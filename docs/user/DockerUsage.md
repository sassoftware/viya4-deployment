# Using Docker Container

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

## Preparation

### Docker image

Run the following command to create the `viya4-deployment` Docker image using the provided [Dockerfile](../../Dockerfile)

```bash
docker build -t viya4-deployment .
```
The Docker image `viya4-deployment` will contain ansible, cloud provider cli's and 'kubectl' executables. The Docker entrypoint for the image is `ansible-playbook` that will be run with sub-commands in the subsequent steps.

### Cloud Authentication

#### GCP
volume mount
variable in ansible vars


### Docker Volume Mounts

All configs needed by ansible are also needed to be mounted into the docker container. In general any file/folder path set via an ansible flag are equivalent to the file/folder being mounted to the docker container at `/config/<lower_case_variable_name>`. 

See [Docker Volume Mapping](DockerVolumeMounts.md) for the full list of docker volume mappings.

Examples:

- The ansible flag `-e KUBECONFIG` is equivalent to `--volume <desire_path>:/config/kubeconfig` when running the docker container
- The ansible flag `-e JUMP_SVR_PRIVATE_KEY` is equivalent to `--volume <desire_path>:/config/jump_svr_private_key` when running the docker container
- The ansible flag `-e V4_CFG_SITEDEFAULT` is equivalent to `--volume <desire_path>:/config/v4_cfg_sitedefault` when running the docker container

Below are the only exceptions:

| Ansible Flag | Docker Mount Path | Description | Required |
| :--- | :--- | :--- | ---: |
| -e BASE_DIR | `/data` | local folder in which all the generated files can be stored. If you do not wish to save the files, this can be omitted | false |
| --vault-password-file | `/config/vault_password_file` | Full path to file containing the vault password | false |

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running

When running, you need to tell the tool with tasks and actions you would like performed

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

- I have a new cluster, deployed using one of the Viya4 IAC projects, and want to install everything

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME:/data \
    --volume $HOME/ansible-vars.yaml:/config/config \
    --volume $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,uninstall"


- I have an existing cluster with viya installed and want to install another viya instance in a different namespace with monitoring

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME:/data \
    --volume $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/defaults.yaml:/config/config \
    --volume $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.ssh:/config/jump_svr_private_key \
    --volume $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.kube:/config/kubeconfig \
    viya4-deployment --tags "viya,viya-monitoring,install"
  ```

- I have a cluster with everything installed and want to uninstall everything

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME:/data \
    --volume $HOME/ansible-vars.yaml:/config/config \
    --volume $HOME/viya4-iac-aws/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,uninstall"
  ```
