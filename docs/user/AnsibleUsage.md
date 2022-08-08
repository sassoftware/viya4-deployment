# Using Ansible

## Prereqs

When using the Ansible CLI, make sure you have all the necessary tools [installed on your workstation](Dependencies.md#dependency-versions).

## Preparation

### Cloud Authentication

See [ansible cloud authentication](AnsibleCloudAuthentication.md) when deploying to GCP with external postgres

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values). The only variable that cannot be set in the ansible-vars files and instead must be set with the `-e` flag is `-e CONFIG=<path_to_ansible_vars_file>`. All other values can be set either in the ansible-vars.yaml file or using the `-e` extra var param in ansible.

### Initialize Ansible

```bash
# install python packages
pip3 install --user -r requirements.txt

# install ansible collections
ansible-galaxy collection install -r requirements.yaml -f
```

## Running

Declare the Actions and Task to be performed.

### Actions

Actions are used to install or uninstall software. One must be set when running the playbook.

| Name | Description |
| :--- | ---: |
| install | Installs the stack required for the specified tasks |
| uninstall | Uninstalls the stack required for the specified tasks |

### Tasks

Any number of tasks can be run at the same time. An action can run against a single task or all tasks.

| Name | Description |
| :--- | :--- |
| baseline | Installs cluster level tooling needed for all viya deployments. These may include, cert-manager, ingress-nginx, nfs-client-provisioners and more. |
| viya | Deploys viya |
| cluster-logging | Installs cluster-wide logging using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| cluster-monitoring | Installs cluster-wide monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| viya-monitoring | Installs viya namespace level monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |

### Examples

- I have a new cluster, deployed using one of the Viya4 IAC projects, and want to install everything

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install"
  ```

- I have a custom built cluster and want to baseline and deploy viya only

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

- I want to modify a customization under site-config for an existing viya deployment and reapply the manifest. I wish to continue to use the same deployment assets rather than pull the latest copy.

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/terraform.tfstate \
    -e V4_CFG_DEPLOYMENT_ASSETS=$HOME/deployments/deployment_assets.tgz \
    playbooks/playbook.yaml --tags "viya,install"
  ```

- I have an existing cluster with viya installed and want to install another viya instance in a different namespace with monitoring

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/test-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "viya,viya-monitoring,install"
  ```

- I have a cluster with a single viya install as well as the monitoring and logging stack. I want to uninstall everything

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/test-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,uninstall"
  ```
