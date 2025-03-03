# Using Docker Container

## Prereqs

- Docker [installed on your workstation](Dependencies.md#docker).

## Preparation

### Docker image

Run the following command to create the `viya4-deployment` Docker image using the provided [Dockerfile](../../Dockerfile)

```bash
docker build -t viya4-deployment .
```
The Docker image `viya4-deployment` will contain ansible, cloud provider cli's and 'kubectl' executables. The Docker entrypoint for the image is `ansible-playbook` that will be run with sub-commands in the subsequent steps.

### Cloud Authentication

The docker container includes the necessary cloud clis for interacting with the cloud providers. See [ansible cloud authentication](AnsibleCloudAuthentication.md) when deploying to Google Cloud with external postgres

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
| --vault-password-file | `/config/vault_password_file` | Full path to file containing the Ansible vault password | false |

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running

Declare the Actions and Task to be performed

### Actions

Actions are used to install or uninstall software. One must be set when running the playbook.

| Name | Description |
| :--- | ---: |
| install | Installs the stack required for the specified tasks |
| uninstall | Uninstalls the stack required for the specified tasks |

### Tasks

More than one task can be run at the same time. An action can run against a single task or all tasks.

| Name | Description |
| :--- | :--- |
| baseline | Installs cluster level tooling needed for all SAS Viya platform deployments. These may include, cert-manager, ingress-nginx, nfs-client-provisioners and more. |
| viya | Deploys the SAS Viya platform |

### Examples

- I have a new cluster, deployed using one of the Viya4 IAC projects, and want to install everything

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME/deployments:/data \
    --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml:/config/config \
    --volume $HOME/deployments/dev-cluster/terraform.tfstate:/config/tfstate \
    --volume $HOME/.ssh/id_rsa:/config/jump_svr_private_key \
    viya4-deployment --tags "baseline,viya,install"
  ```

- I have a custom built cluster and want to install baseline dependencies only

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

- I want to modify a customization under site-config for an existing viya deployment and reapply the manifest. I wish to continue to use the same deployment assets rather than pull the latest copy.

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME/deployments:/data \
    --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml:/config/config \
    --volume $HOME/deployments/dev-cluster/terraform.tfstate:/config/tfstate \
    --volume $HOME/deployments/dev-cluster/dev-namespace/deployment_assets.tgz:/config/v4_cfg_deployment_assets \
    --volume $HOME/.ssh/id_rsa:/config/jump_svr_private_key \
    viya4-deployment --tags "viya,install"
  ```

- I have an existing cluster with viya installed and want to install another viya instance in a different namespace

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME/deployments:/data \
    --volume $HOME/deployments/dev-cluster/test-namespace/ansible-vars.yaml:/config/config \
    --volume $HOME/deployments/dev-cluster/.ssh/id_rsa:/config/jump_svr_private_key \
    --volume $HOME/deployments/dev-cluster/.kube/config:/config/kubeconfig \
    viya4-deployment --tags "viya,install"
  ```

- I have a cluster with a single viya install. I want to uninstall everything

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME/deployments:/data \
    --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml:/config/config \
    --volume $HOME/deployments/dev-cluster/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,uninstall"
  ```

### Monitoring and Logging

To install SAS Viya Monitoring for Kubernetes, see the GitHub project https://github.com/sassoftware/viya4-monitoring-kubernetes for scripts and customization options 
to deploy metric monitoring, alerts and log-message aggregation for SAS Viya.
