
````markdown
#  Migration Guide: NFS Subdir-External Provisioner to CSI NFS Driver

This document outlines the steps required to migrate from the legacy `nfs-subdir-external-provisioner` to the CSI-based `csi-driver-nfs` in a SAS Viya 4 environment on Azure.

> This guide assumes you are migrating a Viya deployment (e.g., `v8.2.1`) to a newer version (e.g., `v9.0.0`) using the latest DaC baseline that includes the `csi-driver-nfs`.

---

##  Prerequisites

- Ensure you have **cluster admin access**.
- The **NFS server** used in the existing setup must be retained and accessible.
- All **PVs and PVCs** should be backed up as a precaution.

---

##  Migration Steps

###  Backup Existing Viya Environment (Manual Trigger)

Trigger a manual backup of your running Viya deployment:

```bash
kubectl create job --from=cronjob/sas-scheduled-backup-all-sources manual-backup-$(date +%s) -n <viya-namespace>
````

Verify the backup job has completed successfully:

```bash
kubectl get jobs \
  -l "sas.com/sas-backup-id=<backup-id>" \
  -L "sas.com/sas-backup-id,sas.com/backup-job-type,sas.com/sas-backup-job-status,sas.com/backup-persistence-status"
```

---

###  Stop the Viya Deployment

Stop the SAS Viya environment using the cron job:

```bash
kubectl -n <viya-namespace> create job --from=cronjob/sas-stop-all stopdep-<datestamp>
```

**Example:**

```bash
kubectl -n viya4 create job --from=cronjob/sas-stop-all stopdep-22072025
```

---

###  Delete Old NFS Provisioner Components

Remove the `sas` StorageClass:

```bash
kubectl delete storageclass sas
```

Delete the namespace used by the legacy provisioner (typically `nfs-client`):

```bash
kubectl delete namespace nfs-client
```

---

###  Deploy New Viya Environment with CSI Driver

Redeploy SAS Viya using the updated DaC baseline that includes CSI NFS driver support.

>  **Important Note:** You do **not** need to restore from backup, as the NFS server path to the PVs remains the same. The CSI driver will reuse existing PVs and directories automatically.

---

## 🔍 Post-Migration Steps

* ✅ Confirm all PVCs are **bound and mounted correctly** in the new Viya deployment.
* 🔄 Validate **data availability** and application functionality.
* 📝 Finalize documentation and update the `README.md` or internal documentation as needed.

---

## 📌 Notes

* The **CSI NFS driver** offers improved compatibility with newer Kubernetes versions and is the **recommended** provisioner going forward.
* Avoid reusing the old Helm release metadata (`meta.helm.sh/*`) to prevent installation or upgrade conflicts.

---
