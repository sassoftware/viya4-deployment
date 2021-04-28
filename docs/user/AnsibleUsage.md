# Using Docker Container

## Prereqs

When using the Ansbile CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#ansible).

## Preparation

### Cloud Authentication

The docker container contains the carious cloud clis for interacting with the various clouds.

#### GCP

When deploying to GCP and using Google Cloud SQL the tool can setup the service account and binding in order to deploy [cloud-sql-proxy](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine). For security we use a workload identity. In order to set the binding, we need a service account with IAM permissions. The following vars are required

- V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME: Name of service account that matches the name inside the V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH file
- V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH: Path to authenticaion file (json) for V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME
- V4_CFG_POSTGRES_CONNECTION_NAME: Sql cluster connection name
- V4_CFG_POSTGRES_SERVICE_ACCOUNT: Service account in GCP with cloudsql.admin role

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values). The only variable that cannot be set in the ansible-vars files and instead must be set with the `-e` flag is `-e CONFIG=<path_to_ansible_vars_file>`. All other values can be set either in the ansible-vars.yaml file or using the `-e` extra var param in ansible.

## Running

When running, you need to tell the tool what tasks and actions you would like performed. 

### Actions

Actions are used to determine whether in install or uninstall software. One must be set when running the playbook

| Name | Description |
| :--- | ---: |
| Install | Installs the stack required for the specified tasks |
| Uninstall | Uninstalls the stack required for the specified tasks |

### Tasks

Any number of tasks can be ran at the same time. This means you could run an action against a single task or all the task.

| Name | Description |
| :--- | :--- |
| baseline | Installs needed cluster level tooling needed for all viya deployments. These may include, cert-manager, ingress-nginx, nfs-client-provisioners and more |
| viya | Deploys viya |
| cluster-logging | Installs cluster-wide logging using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| cluster-monitoring | Installs cluster-wide monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| viya-monitoring | Installs viya namespace level monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |

### Examples

- I have a new cluster, deployed using one of the Viya4 IAC projects, and want to install everything using ansible

  ```bash
  ansible-playbook \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e TFSTATE=$HOME/viya4-iac-aws/terraform.tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install"
  ```

- I have a custom built cluster and want to baseline and deploy viya only using ansible

  ```bash
  ansible-playbook \
    -e KUBECONFIG=$HOME/.kube/config \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```
