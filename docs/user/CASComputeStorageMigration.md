# CAS/Compute Storage – NFS to PVC Migration

- [CAS/Compute Storage – NFS to PVC Migration](#cascompute-storage--nfs-to-pvc-migration)
  - [Background](#background)
  - [What is Covered by This Migration](#what-is-covered-by-this-migration)
  - [Prerequisites](#prerequisites)
  - [Migration Steps (for Existing Deployments Upgrading)](#migration-steps-for-existing-deployments-upgrading)
    - [1. Move Home Directories to the New PVC Path](#1-move-home-directories-to-the-new-pvc-path)
    - [2. Move Data Directories to the New PVC Path](#2-move-data-directories-to-the-new-pvc-path)
    - [3. Update the Identities Service Configuration](#3-update-the-identities-service-configuration)
    - [4. Resume the Environment and Validate](#4-resume-the-environment-and-validate)
  - [Known Remaining Gap (Important — Not Fixed by This Migration)](#known-remaining-gap-important--not-fixed-by-this-migration)
  - [Scope Boundary](#scope-boundary)
  - [Reference](#reference)

## Background

DaC (viya4-deployment) is moving CAS and Compute shared storage (homes and data directories) from direct NFS mounts to PVC-backed storage. This change is driven by security and compliance requirements, including OpenShift `restricted` and `restricted-v2` Security Context Constraints (SCC) environments, where direct NFS mounts are not permitted.

## What is Covered by This Migration

- CAS/Compute shared storage — homes and data directories — moves from raw NFS paths to PVC-backed volumes.
- Existing deployments require a one-time data migration and a configuration update during upgrade.

## Prerequisites

- Cluster admin access to the namespace hosting the SAS Viya Platform deployment.
- Direct access (for example, SSH or jump server access) to both the existing NFS export and the new PVC-backed mount paths so that `rsync` can be run between them.
- Sufficient free space on the new PVC-backed volumes to hold the existing homes and data content.
- The SAS Viya Platform environment should be stopped (for example, using the `sas-stop-all` cron job) before migrating data, to avoid files changing while they are being copied.

## Migration Steps (for Existing Deployments Upgrading)

> **Note:** Replace `<OLD_NFS_HOMES_PATH>`, `<NEW_PVC_HOMES_PATH>`, `<OLD_NFS_DATA_PATH>`, and `<NEW_PVC_DATA_PATH>` with the actual paths in your environment.

### 1. Move Home Directories to the New PVC Path

Run a dry run first to confirm what will be copied, then perform the actual copy, verify there are no remaining differences, and finally remove the old data:

```bash
# Dry run - review the output before proceeding
sudo rsync -aHAXn --stats <OLD_NFS_HOMES_PATH>/ <NEW_PVC_HOMES_PATH>/

# Perform the actual copy
sudo rsync -aHAX --info=progress2 <OLD_NFS_HOMES_PATH>/ <NEW_PVC_HOMES_PATH>/

# Verify - no changes expected
sudo rsync -aHAXni <OLD_NFS_HOMES_PATH>/ <NEW_PVC_HOMES_PATH>/

# Remove the old data only after verification shows no differences
sudo find <OLD_NFS_HOMES_PATH>/ -mindepth 1 -delete
```

### 2. Move Data Directories to the New PVC Path

Repeat the same dry run / copy / verify / cleanup sequence for the data directory:

```bash
# Dry run - review the output before proceeding
sudo rsync -aHAXn --stats <OLD_NFS_DATA_PATH>/ <NEW_PVC_DATA_PATH>/

# Perform the actual copy
sudo rsync -aHAX --info=progress2 <OLD_NFS_DATA_PATH>/ <NEW_PVC_DATA_PATH>/

# Verify - no changes expected
sudo rsync -aHAXni <OLD_NFS_DATA_PATH>/ <NEW_PVC_DATA_PATH>/

# Remove the old data only after verification shows no differences
sudo find <OLD_NFS_DATA_PATH>/ -mindepth 1 -delete
```

### 3. Update the Identities Service Configuration

After the file move is complete, update the identities service configuration to point at the new PVC path:

1. Open **SAS Environment Manager**.
2. Navigate to **Configuration > All Services > Identities service**.
3. Set `sas.identities -> identifier.homeDirectoryPrefix` to `<NEW_PVC_HOMES_PATH>`.
4. Save the configuration and allow the identities service to pick up the change (restart the service if required).

### 4. Resume the Environment and Validate

- Restart the SAS Viya Platform environment (for example, using the `sas-start-all` cron job).
- Confirm that CAS and Compute pods start successfully and mount the new PVCs.
- Validate that user home directories and CAS/Compute data are accessible as expected from a representative set of user sessions.

## Known Remaining Gap (Important — Not Fixed by This Migration)

Even after completing this migration, the Compute launcher still mounts each user's home directory via a **direct NFS mount at session runtime**. This behavior is configured via the [launcher-nfs-mount.yaml](/roles/vdm/templates/transformers/launcher-nfs-mount.yaml) `sas-launcher-nfs-mount` PatchTransformer.

This transformer only adds an annotation telling the Launcher which NFS server to use — the Launcher itself always builds this as a raw NFS mount per user session, and never as a PVC. This mount behavior is implemented inside the Launcher/Compute service itself, not something DaC/Kustomize can change.

## Scope Boundary

**In scope:**
- CAS/Compute shared storage migration (homes, data) — fully validated and can be owned independently.

**Outside scope:**
- Per-session Compute launcher NFS mount — requires the Launcher/Compute team to add PVC support. This cannot be validated or changed via Kustomize.

## Reference

- See also: [Troubleshooting - CAS and Compute Storage Change](../Troubleshooting.md#cas-and-compute-storage-change) and [CONFIG-VARS - NFS Storage](../CONFIG-VARS.md#nfs-storage).
