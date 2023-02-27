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

## EKS - Cluster Autoscaler Installation

### Symptom:
While baselining your 1.25+ EKS cluster using the viya4-deployment project the "Deploy cluster-autoscaler" task failed with a timeout

```bash
TASK [baseline : Deploy cluster-autoscaler] ************************************
task path: /viya4-deployment/roles/baseline/tasks/cluster-autoscaler.yaml:15
fatal: [localhost]: FAILED! => changed=false 
  command: /usr/local/bin/helm --version=9.25.0 --repo=https://kubernetes.github.io/autoscaler upgrade 
  -i --reset-values --wait -f=/tmp/tmpzoxsdrsu.yml cluster-autoscaler cluster-autoscaler
  msg: |-
    Failure when executing Helm command. Exited 1.
    stdout: Release "cluster-autoscaler" does not exist. Installing it now.
  
    Error: timed out waiting for the condition
  stderr: |-
    Error: timed out waiting for the condition
  stderr_lines: <omitted>
  stdout: |-
    Release "cluster-autoscaler" does not exist. Installing it now.
  stdout_lines: <omitted>
```

When checking out the `cluster-autoscaler-aws-cluster-autoscaler-xxx-x` in your cluster you see that it's stuck in a CrashLoopBackoff and checking the pods logs you will see the following error (usually near the beginning logs) and a large Stacktrace

```bash
$ kubectl get pods -n kube-system --selector app.kubernetes.io/instance=cluster-autoscaler
NAME                                                         READY   STATUS             RESTARTS        AGE
cluster-autoscaler-aws-cluster-autoscaler-6c496cc6cc-zftxp   0/1     CrashLoopBackOff   7 (4m42s ago)   15m
$ kubectl logs -n kube-system cluster-autoscaler-aws-cluster-autoscaler-6c496cc6cc-zftxp
... truncated
F0227 16:39:34.624005       1 aws_cloud_provider.go:386] Failed to generate AWS EC2 Instance Types: UnauthorizedOperation: You are not authorized to perform this operation.
        status code: 403, request id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
... stacktrace truncated
```
### Diagnosis:

The "Deploy cluster-autoscaler" task attempted to deploy the 9.25.0 autoscaler helm chart (or newer if you chose to override `CLUSTER_AUTOSCALER_CHART_VERSION`) into your cluster, however the autoscaler deployment failed to start up due to the cluster-autoscaler role having insufficient policies configured.  

As of [release viya4-deployment:6.3.0](https://github.com/sassoftware/viya4-deployment/releases/tag/6.3.0) when installing the cluster-autoscaler on EKS 1.25+ clusters, the [helm chart version 9.25.0](https://github.com/kubernetes/autoscaler/releases/tag/cluster-autoscaler-chart-9.25.0) is used for compatibility reasons. This is because Kubernetes 1.25 has deprecated the `PodDisruptionBudget policy/v1beta1` API version in favor of `policy/v1` and this updated cluster-autoscaler version supports that change. This updated cluster-autoscaler chart requires a modified policy for the cluster-autoscaler role to properly function.

Note: As documented in our [CONFIG-VARS.md](./CONFIG-VARS.md), EKS 1.24 and lower clusters will still default to version 9.9.2 of the cluster-autoscaler helm chart.

### Solution:

Note: If you used viya4-iac-aws:5.6.0 or never to create your infrastructure, these steps are not applicable for you. This role & policy should already be correct. 

1. Scale the `cluster-autoscaler-aws-cluster-autoscaler` deployment down to 0
      ```bash
      kubectl scale --replicas=0 deployment/cluster-autoscaler-aws-cluster-autoscaler
      ```
   Use one of the two options below: 
   1. If you created your 1.25 EKS infrastructure prior to version 5.6.0 of the [viya4-iac-aws](https://github.com/sassoftware/viya4-iac-aws) project, after pulling the latest release you can run the following to update the cluster-autoscaler policy:
       ```bash
       terraform apply -auto-approve \
         -target=module.autoscaling["0"].aws_iam_policy.worker_autoscaling \
         -var-file ${PATH_TO_TFVARS} -state ${PATH_TO_TFSTATE}
       ```
      See Docker & Terraform usage in the [viya4-iac-aws documentation](https://github.com/sassoftware/viya4-iac-aws/tree/main/docs/user) for additional usage information
   2. Alternatively, if you have access to the AWS Console and go into the [IAM Roles](https://us-east-1.console.aws.amazon.com/iamv2/home#/roles) page and update the cluster-autoscaler role yourself.
      * Once you are on the Roles page search for "cluster-autoscaler" and choose the one for your cluster.
      * Under the "Permissions" tab expand the "eks-worker-autoscaling" policy
      * Update the `eksWorkerAutoscalingAll` & `eksWorkerAutoscalingOwn` Sids so that it matches the IAM policy as recommend by the [kubernetes/autoscaler documentation](https://github.com/kubernetes/autoscaler/blob/cluster-autoscaler-chart-9.25.0/cluster-autoscaler/cloudprovider/aws/README.md). Make sure to leave the `Condition` block as is.
        * Switch the repo to the tag of the version of the cluster-autoscaler you are deploying, so that you are viewing the correct documentation.
2. Scale the `cluster-autoscaler-aws-cluster-autoscaler` deployment back to 1
      ```bash
      kubectl scale --replicas=1 deployment/cluster-autoscaler-aws-cluster-autoscaler
      ```