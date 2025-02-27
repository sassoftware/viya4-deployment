# Using Ansible

## Prereqs

When using the Ansible CLI, make sure you have all the necessary tools [installed on your workstation](Dependencies.md#dependency-versions).

## Preparation

### Cloud Authentication

See [ansible cloud authentication](AnsibleCloudAuthentication.md) when deploying to Google Cloud with external postgres

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values). The only variable that cannot be set in the ansible-vars files and instead must be set with the `-e` flag is `-e CONFIG=<path_to_ansible_vars_file>`. All other values can be set either in the ansible-vars.yaml file or using the `-e` extra var param in ansible.

### Initialize Ansible

```bash
# install python packages
pip3 install --user -r requirements.txt

# install ansible collections
ansible-galaxy collection install -r requirements.yaml -f
```

### Install Docker

See https://docs.docker.com/engine/install/ for steps on how to install Docker for your distro. It's a requirement to use the Orchestration tooling CLI during Viya installation.

## Running

Declare the Actions and Task to be performed.

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
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

- I have a custom built cluster and want to install baseline dependencies only

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/.kube/config \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,install"
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

- I have an existing cluster with viya installed and want to install another viya instance in a different namespace

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/test-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "viya,install"
  ```

- I have a cluster with a single viya install. I want to uninstall everything

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME/deployments \
    -e CONFIG=$HOME/deployments/dev-cluster/test-namespace/ansible-vars.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,uninstall"
  ```

### Ansible Config

In the examples above, we are running `ansible-playbook` from within the project directory. This means Ansible will automatically load the project's `ansible.cfg` file which contains configuration settings to properly run this project's playbook. If you are calling the playbook from a directory outside of this project's folder, it is important to set the following Ansible environment variable prior to running the playbook so that the configuration file gets loaded.

```bash
export ANSIBLE_CONFIG=${WORKSPACE}/viya4-deployment/ansible.cfg
```

### Monitoring and Logging

To install SAS Viya Monitoring for Kubernetes, see the GitHub project https://github.com/sassoftware/viya4-monitoring-kubernetes for scripts and customization options 
to deploy metric monitoring, alerts and log-message aggregation for SAS Viya.
