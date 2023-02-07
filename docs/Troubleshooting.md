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
While deploying the SAS Viya platform to a cluster with the "cluster-logging" and "install" Ansible task tags specified, the following error message is encountered.

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
The cluster-logging task tried to deploy an older, incompatible release of sassoftware/viya4-monitoring-kubernetes (i.e. a release earlier than version 1.2.0) using a release of sassoftware/viya4-deployment at release 5.0.0 or later.
Release 5.0.0 (and later) of sassoftware/viya4-deployment is only compatible with sassoftware/viya4-monitoring-kubernetes release 1.2.0 (and later).

### Solution:
When using sassoftware/viya4-deployment releases 5.0.0 or later, specify either the stable branch or a valid sassoftware/viya4-monitoring-kubernetes release tag of 1.2.0 or later for the value of the V4M_VERSION sassoftware/viya4-deployment variable, For more details on supported variables, refer to [CONFIG-VARS.md](./CONFIG-VARS.md)

## SAS Viya Orchestration Tool

### Symptom:
While deploying the SAS Viya platform to a cluster by running the viya4-deployment project directly on your host with the "viya" and "install" Ansible task tags specified (see [AnsibleUsage.md](./user/AnsibleUsage.md)), the following error message is encountered when the "vdm - orchestration" task executes:

```bash
TASK [vdm : orchestration - log into V4_CFG_CR_HOST] ******************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "Error connecting: Error while fetching server API version: ('Connection aborted.', FileNotFoundError(2, 'No such file or directory'))"}
```

### Diagnosis:
The orchestration task attempted to log into the container registry defined by `V4_CFG_CR_URL` using the Python Docker client and failed to do so since it could not communicate with the local Docker Engine API.

### Solution:

As of [release 6.0.0](https://github.com/sassoftware/viya4-deployment/releases/tag/6.0.0), it's required that if you are running this project using Ansible directly on your workstation, it needs Docker to be installed and the executing user should be able to access it. This is so that we can consume the [sas-orchestration tool](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/p0nid9gu3x2cvln1pzpcxa68tpom.htm#p1garxk7w4avg2n1hd6e4nt5kks7), which is available as a Docker image to generate the [SASDeployment Custom Resource file](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/p0nid9gu3x2cvln1pzpcxa68tpom.htm#p012wq5dhcqbx8n12abyqe25m4nu)

On your host:
* Ensure that Docker is installed on your machine, the [Dependency Versions documentation](./user/Dependencies.md) states that you need at least version 20.10.10.
* If Docker is already installed on you machine ensure that the deamon is running, see the [Docker documentation](https://docs.docker.com/config/daemon/start/).

## SAS Viya Deployment Operator

### Symptom:
When the SAS Viya Platform Deployment Operator is not working as expected, three different sources can be used to diagnose problems. Follow the commands from the [SAS Viya Platform deployment guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/p127f6y30iimr6n17x2xe9vlt54q.htm#p11o2ghzdkqm6kn1qkxqr2wr3nkh) to check out the SAS Viya Platform Deployment Operator Pod, the SASDeployment Custom Resource, and the Reconcile Job. Remediation steps are also present on that page.


