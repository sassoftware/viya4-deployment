# CAS/Compute Storage – NFS to PVC Migration

- [CAS/Compute Storage – NFS to PVC Migration](#cascompute-storage--nfs-to-pvc-migration)
  - [Background and Scope](#background-and-scope)
  - [Prerequisites and Safety](#prerequisites-and-safety)
  - [Reporter-Verified Migration Procedure](#reporter-verified-migration-procedure)
    - [1. Select the Source and Destination](#1-select-the-source-and-destination)
    - [2. Set Up Backup and Logging](#2-set-up-backup-and-logging)
    - [3. Check the Paths](#3-check-the-paths)
    - [4. Stop SAS Viya](#4-stop-sas-viya)
    - [5. Back Up the Source](#5-back-up-the-source)
    - [6. Move the Files and Restore Directory Dates](#6-move-the-files-and-restore-directory-dates)
    - [7. Verify the Move](#7-verify-the-move)
    - [8. Update the Identities Service Configuration](#8-update-the-identities-service-configuration)
    - [9. Start SAS Viya and Validate](#9-start-sas-viya-and-validate)
    - [10. Delete the Backup](#10-delete-the-backup)
  - [Rollback](#rollback)
    - [R1. Select the Same Source and Destination](#r1-select-the-same-source-and-destination)
    - [R2. Find the Latest Run and Check It](#r2-find-the-latest-run-and-check-it)
    - [R3. Move Back and Restore Modified Dates](#r3-move-back-and-restore-modified-dates)
    - [R4. Last Resort: Restore from the Backup](#r4-last-resort-restore-from-the-backup)
  - [Known Remaining Gap](#known-remaining-gap)
  - [Reference](#reference)

## Background and Scope

DaC (viya4-deployment) is moving CAS and Compute shared storage (homes and data directories) from direct NFS mounts to PVC-backed storage. This change is driven by security and compliance requirements, including OpenShift `restricted` and `restricted-v2` Security Context Constraints (SCC) environments, where direct NFS mounts are not permitted.

This guide covers the one-time data move and configuration update for existing deployments upgrading to the PVC-backed paths. Fresh deployments do not need this data migration.

The move procedure below is based on a reporter-tested and verified guide. It uses `mv` for an instant rename when both paths are on the same mounted filesystem; this preserves file contents, ownership, permissions, and ACLs without copying file data. The move changes the modified date of each top-level entry, so the procedure records and restores those dates.

The migration applies to both homes and data. Complete the entire procedure for homes, then repeat it from Step 1 for data. Update the identities configuration during the homes pass; during the data pass, skip the identities configuration step because it applies only to homes. Replace all example source and destination paths with paths from your deployment; the sample PVC names and IDs in reporter-provided examples are deployment-specific and must not be reused blindly.

## Prerequisites and Safety

- Access to the jump VM or other host where both the old NFS directory and the new PVC-backed directory are mounted, with Bash, GNU `find`, `mv`, `stat`, `tar`, and `realpath` available.
- `kubectl` access to the Viya namespace to stop and start SAS Viya.
- Enough space next to the source directory for a compressed backup archive. The backup is written beside the source, not inside it.
- Confirm the correct old source path and new PVC destination path for homes and data.
- Stop SAS Viya before taking the backup and moving files. Do not allow workloads to write to either location during the move.
- Do not proceed if any check reports `STOP` or the summary says `DO NOT CONTINUE`.
- The procedure requires the source and destination to be on the same filesystem. If the check reports different mounts, do not use `mv`; use a separately planned and verified copy-based migration instead.
- Do not delete the backup until the environment is started and users' files have been validated.

Run each complete Bash block in the same shell, top to bottom, for one directory at a time. Paste whole blocks, including their opening and closing braces. Each check reports `OK` or `STOP`; resolve every `STOP` before continuing.

## Reporter-Verified Migration Procedure

### 1. Select the Source and Destination

Run **one** block for homes or data. Replace the quoted example paths with the actual mounted paths. `realpath -e` requires that both directories already exist.

Homes:

```bash
SRC=$(realpath -e "/path/to/old/nfs/homes")
DST=$(realpath -e "/path/to/new/pvc/homes")
```

Data:

```bash
SRC=$(realpath -e "/path/to/old/nfs/data")
DST=$(realpath -e "/path/to/new/pvc/data")
```

### 2. Set Up Backup and Logging

Run this immediately after Step 1 so the backup, log, and modified-date filenames all correspond to the selected directory:

```bash
TS=$(date +%Y%m%d-%H%M%S)
BACKUP="$SRC-$TS.tar.gz"
LOG=~/nfs-to-pvc-mv-$(basename "$SRC")-$TS.log
MTIMES=~/nfs-to-pvc-mv-$(basename "$SRC")-$TS.mtimes
COUNT=
log()  { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
ok()   { echo "$(date '+%F %T') OK: $*" >> "$LOG"; printf '\e[1;32m  OK  \e[0m %s\n' "$*"; }
stop() { echo "$(date '+%F %T') STOP: $*" >> "$LOG"; printf '\e[1;97;41m STOP \e[0m %s\n' "$*"; FAILS=$((FAILS+1)); }
summary() {
  if (( FAILS == 0 )); then printf '\n\e[1;97;42m  ALL CHECKS PASSED - OK TO CONTINUE  \e[0m\n\n'
  else printf '\n\e[1;97;41m  %d CHECK(S) FAILED - DO NOT CONTINUE  \e[0m\n\n' "$FAILS"; fi
  log "summary: $FAILS failed" >/dev/null
}
log "SRC=$SRC DST=$DST BACKUP=$BACKUP"
```

### 3. Check the Paths

Run the complete block. Continue only if the summary reports all checks passed:

```bash
{
FAILS=0
[[ -d $SRC && -d $DST ]] && ok "both paths exist" || stop "source or destination does not exist"
[[ $SRC != / && $DST != / && $SRC != "$DST" && $DST != "$SRC"/* && $SRC != "$DST"/* ]] && ok "paths do not overlap" || stop "paths overlap or one is /"
[[ $(stat -f -c %T "$SRC") == nfs* ]] && ok "source is on NFS" || stop "source is not on NFS - is the share mounted?"
[[ $(stat -c %d "$SRC") == "$(stat -c %d "$DST")" ]] && ok "same mount, mv is a rename" || stop "different mounts - do not use mv; plan a copy-based migration"
[[ -n $(sudo find "$SRC" -mindepth 1 -maxdepth 1 -print -quit) ]] && ok "source has data" || stop "source is empty"
[[ -z $(sudo find "$DST" -mindepth 1 -maxdepth 1 -print -quit) ]] && ok "destination is empty" || stop "destination is not empty"
summary
}
```

The destination must be empty and must not overlap the source. The same-filesystem check is essential: across filesystems, `mv` becomes a copy and does not have the same instant-rename behavior.

### 4. Stop SAS Viya

Run this wherever you have `kubectl` access to the cluster (it may be a different machine from the one running the file operations). Set `VIYA_NS` to the namespace for your deployment:

```bash
VIYA_NS=viya
kubectl create job "sas-stop-all-$(date +%s)" --from=cronjobs/sas-stop-all -n "$VIYA_NS"
```

Confirm the stop job has completed and that Viya workloads are stopped before continuing.

### 5. Back Up the Source

The archive is written next to the source directory. Continue only if the archive was created and can be read:

```bash
{
FAILS=0
COUNT=$(sudo find "$SRC" -mindepth 1 | wc -l); log "source entries: $COUNT"
sudo tar --numeric-owner --xattrs --acls -czpf "$BACKUP" -C "$SRC" . && ok "backup written to $BACKUP" || stop "backup failed"
sudo tar -tzf "$BACKUP" >/dev/null && ok "backup is readable ($(sudo du -h "$BACKUP" | cut -f1))" || stop "backup is not readable"
summary
}
```

Keep the `LOG`, `MTIMES`, and backup file paths. The log and modified-date file are needed for rollback.

### 6. Move the Files and Restore Directory Dates

This moves all top-level entries, including hidden files and directories, then restores their original modified dates:

```bash
{
FAILS=0
sudo find "$SRC" -mindepth 1 -maxdepth 1 -printf '%T@\t%f\n' > "$MTIMES" && ok "saved modified dates to $MTIMES" || stop "could not save modified dates"
sudo find "$SRC" -mindepth 1 -maxdepth 1 -exec mv -t "$DST" -- {} + && ok "move finished" || stop "move reported errors - see Rollback"
while IFS=$'\t' read -r t n; do sudo touch -h -m -d "@$t" "$DST/$n" || stop "could not restore modified date of $n"; done < "$MTIMES"
(( FAILS == 0 )) && ok "modified dates restored"
summary
}
```

### 7. Verify the Move

Continue only if the summary reports all checks passed:

```bash
{
FAILS=0
sudo ls -ln "$DST" | head | tee -a "$LOG"
MOVED=$(sudo find "$DST" -mindepth 1 | wc -l); LEFT=$(sudo find "$SRC" -mindepth 1 | wc -l)
[[ -n $COUNT && $MOVED == "$COUNT" && $LEFT == 0 ]] && ok "$MOVED entries moved, source is empty" || stop "expected ${COUNT:-?}, found $MOVED in destination and $LEFT left in source"
BAD=0; while IFS=$'\t' read -r t n; do [[ $(sudo stat -c %Y "$DST/$n" 2>/dev/null) == "${t%.*}" ]] || BAD=$((BAD+1)); done < "$MTIMES"
(( BAD == 0 )) && ok "modified dates match the originals" || stop "$BAD top-level entries have a different modified date"
summary
}
```

### 8. Update the Identities Service Configuration

After moving homes, update the identities service configuration to use the new PVC-backed homes path:

1. Open **SAS Environment Manager**.
2. Navigate to **Configuration > All Services > Identities service**.
3. Set `sas.identities -> identifier.homeDirectoryPrefix` to the new PVC-backed homes path.
4. Save the configuration and allow the identities service to pick up the change (restart the service if required).

For the data pass, repeat the procedure from Step 1 using the data source and destination paths. Skip this identities configuration step; `identifier.homeDirectoryPrefix` applies only to homes.

### 9. Start SAS Viya and Validate

Run this from the same place as Step 4, using the correct namespace:

```bash
VIYA_NS=viya
kubectl create job "sas-start-all-$(date +%s)" --from=cronjobs/sas-start-all -n "$VIYA_NS"
```

Confirm the start job completes successfully. Check that CAS and Compute pods start and that user home directories and CAS/Compute data are accessible as expected. Validate with representative user sessions before deleting the backup.

### 10. Delete the Backup

Only after Viya has started and the migrated files have been validated, delete the archive for this run. The exact path is recorded in the log:

```bash
sudo rm -f "$BACKUP" && log "backup deleted: $BACKUP"
```

## Rollback

Prefer moving the files back with `mv` while the source and destination remain on the same filesystem. Run the rollback blocks in order. Stop SAS Viya before rollback if it has been started, and do not run the migration's Steps 1–2 again.

### R1. Select the Same Source and Destination

Run the same source/destination block from Step 1 for the directory being rolled back.

### R2. Find the Latest Run and Check It

This finds the latest modified-date file for the selected source and derives the log and backup paths from that run. The backup archive is needed only for R4; R3 uses the same-filesystem move and modified-date file. If the archive has already been deleted, R3 may still be possible, but R4 is no longer available.

```bash
{
log()  { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }
ok()   { echo "$(date '+%F %T') OK: $*" >> "$LOG"; printf '\e[1;32m  OK  \e[0m %s\n' "$*"; }
stop() { echo "$(date '+%F %T') STOP: $*" >> "$LOG"; printf '\e[1;97;41m STOP \e[0m %s\n' "$*"; FAILS=$((FAILS+1)); }
summary() {
  if (( FAILS == 0 )); then printf '\n\e[1;97;42m  ALL CHECKS PASSED - OK TO CONTINUE  \e[0m\n\n'
  else printf '\n\e[1;97;41m  %d CHECK(S) FAILED - DO NOT CONTINUE  \e[0m\n\n' "$FAILS"; fi
  log "summary: $FAILS failed" >/dev/null
}
FAILS=0
MTIMES=$(ls -t ~/nfs-to-pvc-mv-"$(basename "$SRC")"-*.mtimes 2>/dev/null | head -n1)
[[ -n $MTIMES ]] && LOG=${MTIMES%.mtimes}.log || LOG=~/nfs-to-pvc-mv-$(basename "$SRC")-rollback.log
TS=${MTIMES%.mtimes}; TS=${TS: -15}
BACKUP="$SRC-$TS.tar.gz"
log "rollback: SRC=$SRC DST=$DST MTIMES=$MTIMES BACKUP=$BACKUP"
[[ -s $MTIMES ]] && ok "dates file: $MTIMES" || stop "no dates file found for $(basename "$SRC")"
if sudo test -s "$BACKUP"; then ok "backup from the same run: $BACKUP"; else log "WARNING: backup not found: $BACKUP (R4 unavailable)"; fi
sudo test -e "$DST/$(head -n1 "$MTIMES" | cut -f2)" && ok "dates file matches destination" || stop "dates file does not match $DST"
[[ -n $(sudo find "$DST" -mindepth 1 -maxdepth 1 -print -quit) ]] && ok "destination has data to move back" || stop "destination is empty"
[[ -z $(sudo find "$SRC" -mindepth 1 -maxdepth 1 -print -quit) ]] && ok "source is empty" || stop "source is not empty"
summary
}
```

### R3. Move Back and Restore Modified Dates

Run only after the rollback checks pass:

```bash
{
FAILS=0
sudo find "$DST" -mindepth 1 -maxdepth 1 -exec mv -t "$SRC" -- {} + && ok "moved back to $SRC" || stop "move back reported errors"
while IFS=$'\t' read -r t n; do sudo touch -h -m -d "@$t" "$SRC/$n" || stop "could not restore modified date of $n"; done < "$MTIMES"
(( FAILS == 0 )) && ok "modified dates restored"
summary
}
```

### R4. Last Resort: Restore from the Backup

Use this only if moving the files back is not possible (for example, if the destination was damaged), and only after confirming the correct backup and source paths:

```bash
sudo tar --numeric-owner --xattrs --acls -xzpf "$BACKUP" -C "$SRC" && log "restored $BACKUP into $SRC"
```

## Known Remaining Gap

Even after completing this migration, the Compute launcher still mounts each user's home directory via a **direct NFS mount at session runtime**. This behavior is configured via the [launcher-nfs-mount.yaml](/roles/vdm/templates/transformers/launcher-nfs-mount.yaml) `sas-launcher-nfs-mount` PatchTransformer.

This transformer only adds an annotation telling the Launcher which NFS server to use — the Launcher itself always builds this as a raw NFS mount per user session, and never as a PVC. This mount behavior is implemented inside the Launcher/Compute service itself, not something DaC/Kustomize can change.

The CAS/Compute shared-storage migration is in viya4-deployment scope. Per-session Compute launcher NFS-to-PVC support is outside this scope, requires the Launcher/Compute team, and cannot be validated or changed via viya4-deployment/Kustomize.

## Reference

[Troubleshooting - CAS and Compute Storage Change](../Troubleshooting.md#cas-and-compute-storage-change) and [CONFIG-VARS - NFS Storage](../CONFIG-VARS.md#nfs-storage).
