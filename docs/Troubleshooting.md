# Troubleshooting

## Debug Mode
Debug mode can be enabled by adding "-vvv" to the end of the docker or ansible commands

Example:

  ```bash
  docker run --rm \
    --group-add root \
    --user $(id -u):$(id -g) \
    --volume $HOME:/data \
    --volume $HOME/ansible-vars.yaml:/config/config \
    --volume $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install" -vvv
  ```

  ```bash
  ansible-playbook \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e TFSTATE=$HOME/viya4-iac-aws/terraform.tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install" -vvv
  ```
## Viya4 Monitoring and Logging
### Symptom:
While deploying Viya4 to a cluster with the "cluster-logging" and "install" Ansible task tags specified, the following error message is encountered.

  ```bash
TASK [monitoring : cluster-logging - deploy] ********************************************************************************
fatal: [localhost]: FAILED! => changed=false
  cmd: /home/user/.ansible/viya4-monitoring-kubernetes/logging/bin/deploy_logging.sh
  msg: '[Errno 2] No such file or directory: b''/home/user/.ansible/viya4-monitoring-kubernetes/logging/bin/deploy_logging.sh'''
  rc: 2

PLAY RECAP ******************************************************************************************************************
localhost                  : ok=52   changed=12   unreachable=0    failed=1    skipped=41   rescued=0    ignored=0
  ```

### Diagnosis:
The cluster-logging task of sassoftware/viya4-monitoring tried to execute code from a release of sassoftware/viya4-monitoring-kubernetes prior to 1.2.0 using a release of sassoftware/viya4-deployment at release 5.0.0 or later.
Releases of sassoftware/viya4-monitoring-kubernetes prior to 1.2.0 do not support the installation of the OpenSearch logging software which sassoftware/viya4-deployment 5.0.0 or later installs.

### Solution:
When using sassoftware/viya4-deployment releases 5.0.0 or later, specify either the stable branch or a valid sassoftware/viya4-monitoring-kubernetes release tag of 1.2.0 or later for the value of the V4M_VERSION sassoftware/viya4-deployment variable, For more details on supported variables, refer to [CONFIG-VARS.md](./CONFIG-VARS.md)
