# Using Ansible

## Prereqs

When using the Ansible CLI, make sure you have all the necessary tools [installed on your workstation](Dependencies.md).

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
