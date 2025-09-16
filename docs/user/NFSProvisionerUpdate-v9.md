
#  Migration Guide: v9.0.0

This guide assumes you are migrating a viya4-deployment (e.g., `v8.2.1`) to a newer version (e.g., `v9.0.0`) using the latest viya4-deployment baseline that includes the `csi-driver-nfs`.

##  Prerequisites

- Ensure you have **cluster admin access**.
- The **NFS server** used in the existing setup must be retained and accessible.
- All **PVs and PVCs** should be backed up as a precaution.

##  Migration Steps

###  Backup Existing Environment (Manual Execution)

Trigger a manual backup of your running viya4-deployment:

```bash
kubectl create job --from=cronjob/sas-scheduled-backup-all-sources manual-backup-$(date +%s) -n <viya4-namespace>
````

Fatch the backup ID

```bash
kubectl describe job <backup-job-name> -n va-viya | grep "sas.com/sas-backup-id"
````

###  Verify the backup job has completed successfully:

```bash
kubectl get jobs \
  -L "sas.com/sas-backup-id,sas.com/backup-job-type,sas.com/sas-backup-job-status,sas.com/backup-persistence-status" -n viya_namespace_name
```
###  Stop the viya4-deployment

Stop the SAS viya4 environment using the cron job:

```bash
kubectl -n <viya4-namespace> create job --from=cronjob/sas-stop-all stopdep-<date +%s>
```

**Example:**

```bash
kubectl -n viya4 create job --from=cronjob/sas-stop-all stopdep-22072025
```
###  Delete Old NFS Provisioner Components

Remove the `sas` StorageClass:
For SAS viya4 environments deployed on Google Cloud Platform (GCP), the legacy `pg-storage` StorageClass must be deleted.

```bash
kubectl delete storageclass sas
```

Delete the namespace used by the legacy provisioner (typically `nfs-client`):

```bash
kubectl delete namespace nfs-client
```

###  Deploy New viya4 Environment with CSI Driver

Update your DaC baseline to install the CSI NFS driver

To install/upgrade baseline dependencies only using "Docker"

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME/deployments:/data \
    --volume $HOME/deployments/dev-cluster/.kube/config:/config/kubeconfig \
    --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml:/config/config \
    --volume $HOME/.ssh/id_rsa:/config/jump_svr_private_key \
    viya4-deployment --tags "baseline,install"
  ```

To install/upgrade baseline dependencies only using "ansible"

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,install"
  ```
If you have redeployed **viya4-deployment** using the [9.0.0 release](https://github.com/sassoftware/viya4-deployment/releases/tag/v9.0.0), which includes CSI NFS driver support, no additional action is required.

However, if you have only updated the viya4-deployment baseline without redeploying viya4, you will need to manually start the viya4 environment using the following command:

```bash
kubectl -n <viya4-namespace> create job --from=cronjob/sas-start-all startdep-<date +%s>
```

>  **Important Note:** You do **not** need to restore from backup, as the NFS server path to the PVs remains the same. The CSI driver will reuse existing PVs and directories automatically.

###  Post-Migration Steps

*  Confirm all PVCs are **bound and mounted correctly** in the new viya4-deployment.
*  Validate **data availability** and application functionality.

---

###  Notes

* The **CSI NFS driver** offers improved compatibility with newer Kubernetes versions and is the **recommended** provisioner going forward.
* Avoid reusing the old Helm release metadata (`meta.helm.sh/*`) to prevent installation or upgrade conflicts.

