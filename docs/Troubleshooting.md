# Troubleshooting

- [Troubleshooting](#troubleshooting)
  - [Viya4 Monitoring and Logging](#viya4-monitoring-and-logging)
  - [SAS Viya Orchestration Tool](#sas-viya-orchestration-tool)
  - [SAS Viya Deployment Operator](#sas-viya-deployment-operator)
  - [EKS - Cluster Autoscaler Installation](#eks---cluster-autoscaler-installation)
  - [kustomize - Generate deployment manifest](#kustomize---generate-deployment-manifest)
  - [Ingress-Nginx issue - Unable to access SAS Viya Platform web apps](#ingress-nginx-issue---unable-to-access-sas-viya-platform-web-apps)
  - [Ansible Variables with Special Jinja2 Characters](#ansible-variables-with-special-jinja2-characters)
  - [Ingress-Nginx - use-forwarded-headers disabled](#ingress-nginx---use-forwarded-headers-disabled)
  - [Deploying with the SAS Orchestration Tool using a Provider Based Kubernetes Configuration File](#deploying-with-the-sas-orchestration-tool-using-a-provider-based-kubernetes-configuration-file)
  - [Applying a New License for your SAS Viya Platform Deployment](#applying-a-new-license-for-your-sas-viya-platform-deployment)
  - [Tagging the AWS EC2 Load Balancers](#tagging-the-aws-ec2-load-balancers)
  - [Deploying with cadence versions > 2024.06 without creating the external PostgreSQL SharedServices database](#deploying-with-cadence-versions--202406-without-creating-the-external-postgresql-sharedservices-database)

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

As of [release 6.0.0](https://github.com/sassoftware/viya4-deployment/releases/tag/6.0.0), it's required that if you are running this project using Ansible directly on your workstation, it needs Docker to be installed and the executing user should be able to access it. This is so that we can consume the [sas-orchestration tool](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p11063ane8wtdtn1ksq12gxzchu8.htm), which is available as a Docker image to generate the [SASDeployment Custom Resource file](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p0nid9gu3x2cvln1pzpcxa68tpom.htm#p012wq5dhcqbx8n12abyqe25m4nu)

On your host:
* Ensure that Docker is installed on your machine, the [Dependency Versions documentation](./user/Dependencies.md) states that you need at least version 20.10.10.
* If Docker is already installed on you machine ensure that the deamon is running, see the [Docker documentation](https://docs.docker.com/config/daemon/start/).

## SAS Viya Deployment Operator

### Symptom:
When the SAS Viya Platform Deployment Operator is not working as expected, three different sources can be used to diagnose problems. Follow the commands from the [SAS Viya Platform deployment guide](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm#p11o2ghzdkqm6kn1qkxqr2wr3nkh) to check out the SAS Viya Platform Deployment Operator Pod, the SASDeployment Custom Resource, and the Reconcile Job. Remediation steps are also present on that page.

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

Note: If you used viya4-iac-aws:5.6.0 or newer to create your infrastructure, these steps are not applicable for you. This role & policy should already be correct. 

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
        * Switch the repository to the tag of the version of the cluster-autoscaler you are deploying, so that you are viewing the correct documentation.
2. Scale the `cluster-autoscaler-aws-cluster-autoscaler` deployment back to 1
      ```bash
      kubectl scale --replicas=1 deployment/cluster-autoscaler-aws-cluster-autoscaler
      ```

## kustomize - Generate deployment manifest

### Symptom:

While deploying the SAS Viya platform to a cluster with the "viya" and "install" Ansible task tags specified, the following error message is encountered when the "vdm : kustomize - Generate deployment manifest" task executes:

```bash
TASK [vdm : kustomize - Generate deployment manifest] ************************
fatal: [localhost]: FAILED! => changed=true
  cmd:
  - kustomize
  - build
  - <omitted>
  - --load_restrictor=none
  - -o
  - <omitted>
  delta: <omitted>
  end: <omitted>
  msg: non-zero return code
  rc: 1
  start: <omitted>
  stderr: |-
    Error: failed to apply json patch '- op: add
      path: /spwc/volumeClaimTemplates/0/spec/storageClassName
       value: sas': add operation does not apply: doc is missing path: "/spec/volumeClaimTemplates/0/spec/storageClassName": missing value
  stderr_lines: <omitted>
  stdout: ''
  stdout_lines: <omitted>
```

### Diagnosis:

The sas-data-agent-server-colocated component was added to the 2022.09 cadence of the SAS Viya Platform. That component contains a StatefulSet object which does not have a "/spec/volumeClaimTemplates/0/spec/storageClassName" path element.  For viya4-deployment releases prior to v5.4.0, a PatchTransformer expects to find that path element in each StatefulSet.

### Solution:

As of [release viya4-deployment:5.4.0](https://github.com/sassoftware/viya4-deployment/releases/tag/5.4.0), the StatefulSet PatchTransformer is intentionally skipped for the sas-data-agent-server-colocated component. Using [release viya4-deployment:5.4.0](https://github.com/sassoftware/viya4-deployment/releases/tag/5.4.0) or later for your SAS Viya Platform deployment will eliminate this error.


## Ingress-Nginx issue - Unable to access SAS Viya Platform web apps
### Symptom:
After upgrading your AKS cluster's Kubernetes version to 1.24 or later, you are unable to access the SAS Viya Platform web apps. All the pods are running and errors are only seen in ingress-nginx logs:

```bash
W0320 20:15:25.141987       7 controller.go:1354] Using default certificate
W0320 20:15:25.141997       7 controller.go:1347] Unexpected error validating SSL certificate "deploy/sas-ingress-certificate-5gc77h2dhg" for server "*.deploy.test.example.com": x509: certificate is valid for test-aks.example.com, not *.deploy.test.example.com
W0320 20:15:25.142005       7 controller.go:1348] Validating certificate against DNS names. This will be deprecated in a future version
W0320 20:15:25.142013       7 controller.go:1353] SSL certificate "deploy/sas-ingress-certificate-5gc77h2dhg" does not contain a Common Name or Subject Alternative Name for server "*.deploy.test.example.com": x509: certificate is valid for test-aks.example.com, not *.deploy.test.example.com
```

### Diagnosis:
This issue is related to Azure LoadBalancer’s probing. The appProtocol support inside cloud provider has broken ingress-nginx for AKS clusters >=1.22. The issue was caused by two reasons:
* the new version of nginx ingress controller added appProtocol and its probe path has to be `/healthz`;
* the new version of cloud-controller-manager added HTTP probing with default path `/` for appProtocol=http services.

The `Custom Load Balancer health probe` section in the [Azure LoadBalancer](https://cloud-provider-azure.sigs.k8s.io/topics/loadbalancer/#custom-load-balancer-health-probe) document states that:

>Tcp, Http and Https are three protocols supported by load balancer service. Currently, the default protocol of the health probe varies among services with different transport protocols, app protocols, annotations and external traffic policies.
>1. for local services, HTTP and /healthz would be used. The health probe will query NodeHealthPort rather than actual backend service
>2. for cluster TCP services, TCP would be used.
>3. for cluster UDP services, no health probes.
>
> Since v1.20, service annotation `service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path` is introduced to determine the health probe behavior.
  >- For clusters <=1.23, spec.ports.appProtocol would only be used as probe protocol when `service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path` is also set.
  > - For clusters >1.24, spec.ports.appProtocol would be used as probe protocol and `/` would be used as default probe request path (`service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path` could be used to change to a different request path).

To resolve this issue the ingress-nginx version should be 1.3.0 (or later) with the following annotation configured :
> --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

### Solution:
For Users upgrading their AKS cluster's Kubernetes version to 1.24 (or later) and used viya4-deployment v6.3.0 (or prior) for the SAS Viya Platform deployment, you must use viya4-deployment v6.4.0 (or later) and re-run the baseline install task.

If you prefer to continue using the existing viya4-deployment version then add the following in your ansible-var.yaml and re-run baseline install task :

```bash
INGRESS_NGINX_CHART_VERSION: 4.3.0
INGRESS_NGINX_CONFIG:
  controller:
    service:
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
```

## Ansible Variables with Special Jinja2 Characters

### Symptom:

You execute the viya4-deployment project and an Ansible task that uses a variable that you defined in your [ansible-vars.yaml](https://github.com/sassoftware/viya4-deployment/blob/main/examples/ansible-vars.yaml) fails due to a Jinja2 templating error.

Example task below that failed while consuming the `V4_CFG_CR_PASSWORD` variable from my `ansible-vars.yaml`
```bash
TASK [echo : orchestration tooling - my example task] ******************************************************************
fatal: [127.0.0.1]: FAILED! => {"msg": "An unhandled exception occurred while templating 'A1{%a%}{{b}}{#c#}#d##'. Error was a <class 'ansible.errors.AnsibleError'>, original message: template error while templating string: Encountered unknown tag 'a'.. String: A1{%a%}{{b}}{#c#}#d##"}
```

### Diagnosis:

The variable that you defined in your `ansible-vars.yaml` has a string value that contains a special Jinja2 character sequence that Ansible is attempt to templatize. To see a list of special Jinja2 characters view the list here in the [Jinja2 documentation](https://jinja.palletsprojects.com/en/2.11.x/templates/#synopsis).

### Solution:

Ansible provides the `!unsafe` keyword that you can place in front of your string values to block templating. String values with `!unsafe` in front of them will be read as-is and will not require the user to escape the string themselves. It's important to note that using `!unsafe` does not introduce a security vulnerability like the name may imply, it actually the opposite, marking data as unsafe prevents malicious users from abusing Jinja2 templates to execute arbitrary code on target machines.

Example:
```yaml
# ansible-vars.yaml
V4_CFG_CR_PASSWORD: !unsafe "A1{%a%}{{b}}{#c#}#d##"
```

For additional information about the `!unsafe` keyword see the [Ansible Advanced playbook syntax documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_advanced_syntax.html#unsafe-or-raw-strings)

## Ingress-Nginx - use-forwarded-headers disabled
### Symptom:
In viya4-deployment v6.4.0 or before the default value for `use-forwarded-headers` was set to true. This has raised a security concern and needs to be updated.

### Diagnosis:

The document [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers) states the use of `use-forwarded-headers` as follows:

>If true, NGINX passes the incoming X-Forwarded-* headers to upstream. Use this option when NGINX is behind another L7 proxy / load balancer that is setting these headers.
>
>If false, NGINX ignores incoming X-Forwarded-* headers, filling them with the request information it sees. Use this option if NGINX is exposed directly to the internet, or it's behind a L3/packet-based load balancer that doesn't alter the source IP in the packets.

### Solution:
As NGINX is not behind another L7 proxy / load balancer we are setting the `use-forwarded-headers` to false by default starting viya4-deployment v6.5.0 or later. If you wish to enable the incoming X-Forwarded headers then please add the following in your ansible-vars.yaml file.

```bash
INGRESS_NGINX_CONFIG:
  controller:
    config:
      use-forwarded-headers: "true"
```

## Deploying with the SAS Orchestration Tool using a Provider Based Kubernetes Configuration File

### Symptom:
While deploying the SAS Viya platform into Google Cloud OR AWS cluster using a provider based kubernetes configuration file and setting `V4_DEPLOYMENT_OPERATOR_ENABLED: false` in your `ansible-vars.yaml`, the following error message is encountered:

In Google Cloud:
  ```bash
Error: Cannot create client for namespace 'deploy'
 Caused by:
        * Get " https://11.111.11.111/api?timeout=32s ": getting credentials: exec: executable gke-gcloud-auth-plugin not found
	 
        It looks like you are trying to use a client-go credential plugin that is not installed.
	 
        To learn more about this feature, consult the documentation available at:
        https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins
	 
        Install gke-gcloud-auth-plugin for use with kubectl by following https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
 ```

In AWS:

```bash
Error: Cannot create client for namespace 'deploy'
 Caused by:
        * Get "https://12345678123456781234123456785678.abc.us-west-1.eks.amazonaws.com/api?timeout=32s": getting credentials: exec: executable aws not found

         It looks like you are trying to use a client-go credential plugin that is not installed.

         To learn more about this feature, consult the documentation available at:
               https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins
```

### Diagnosis:

If you are using a provider based kubernetes configuration file; one that relies on external binaries from the cloud provider to authenticate into the kubernetes cluster ([AWS](https://docs.aws.amazon.com/eks/latest/userguide/cluster-auth.html) & [Google Cloud](https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication)), there are deployment constraints you need to consider when planning your SAS Viya platform deployment when using this project. If you are using a "kubernetes service account and cluster role binding" or "static" based kubernetes configuration file it will be compatible will all SAS Viya platform deployment methods as well as ways to execute this project, and the statements below are not applicable.

Some background information, using the `V4_DEPLOYMENT_OPERATOR_ENABLED` flag  in your `ansible-vars.yaml` you are able to control the method of deployment that this project will use to deploy SAS Viya.
* `V4_DEPLOYMENT_OPERATOR_ENABLED: true`, the [SAS Viya Platform Deployment Operator](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm) will be installed into the cluster and used to deploy the SAS Viya platform
* `V4_DEPLOYMENT_OPERATOR_ENABLED: false`, the [sas-orchestration command](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm) whose tooling is delivered as a Docker image, is used to deploy the SAS Viya platform

Alongside the two SAS Viya deployments methods, considerations for the two different ways that this project, viya4-deployment, can be run will also need to be made. You can either:
* Clone this project and execute it [using the ansible-playbook](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/AnsibleUsage.md) binary you have installed on your host
* Alternatively you can build a Docker image with the [Dockerfile](https://github.com/sassoftware/viya4-deployment/blob/main/Dockerfile) provided in this repository and run it using the [Docker run command](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/DockerUsage.md).

The combination of setting `V4_DEPLOYMENT_OPERATOR_ENABLED: false` and running directly on your host using the `ansible-playbook` command is where using a provider based kubernetes configuration file is not compatible.

When the `sas-orchestration` tooling is run (as a Docker container) to deploy SAS Viya into the cluster, the required binaries from the cloud provider for authentication are not present, meaning that the tooling will not be able to connect to the cluster to perform the deployment.

When running the viya4-deployment project as a Docker container the `sas-orchestration` tooling is run in a slightly different manner to get around this limitation. We make use of `skopeo` to exact the contents of the `sas-orchestration` tooling image directly into our running viya4-deployment container. Since in our Dockerfile we include the installation of the required authentications binaries for Google Cloud and AWS, the `sas-orchestration` tooling is able to make use of them and successfully connect to the kubernetes cluster.

### Solution:

You have a couple of options:
* If you would still like to deploy the SAS Viya platform with the `sas-orchestration` command with your existing kubernetes configuration file, it is recommended to build the Docker image for this project with the [Dockerfile](https://github.com/sassoftware/viya4-deployment/blob/main/Dockerfile) and run it using the [Docker run command](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/DockerUsage.md).
* If you created your infrastructure with the sassoftware/viya4-iac-* projects, you can go back and set `create_static_kubeconfig=true` and run `terraform apply` again to generate a "static" kubeconfig file that is compatible with `sas-orchestration`.
* Using your existing provider based kubernetes configuration and `kubectl` you can alternatively create a new ServiceAccount, associate a service-account-token to it, and grant it admin permissions using RBAC. You should be able to use the ca cert and token from service-account-token to create your own "static" kubernetes configuration file.
  * See [Kubernetes documentation](https://kubernetes.io/docs/concepts/security/service-accounts/)
  * Note: this is what the option above setting `create_static_kubeconfig=true` and running `terraform apply` would do for you automatically.

## Applying a New License for your SAS Viya Platform Deployment

### Symptom:

You have an existing SAS Viya platform deployment that was created using the viya4-deployment project, and you have a new license that you would like to apply to your deployment.

### Solution:

After downloading the license file perform the following steps:

1. Set `V4_CFG_LICENSE` to path where your license file is located. Note, it is a `.jwt` file.
2. Using viya4-deployment rerun the `viya,install` tasks to regenerate your `kustomization.yaml` that will now have an updated reference to the new license file, generate the SASDeployment custom resource file, and apply it into your cluster.
3. You will see your license file referenced in the `kustomization.yaml` as a generator, look for `site-config/vdm/generators/sas-license.yaml`
   * Note: If you are no longer using viya4-deployment and are updating the license on your own by following the SAS Viya Platform Operations Guide, this would be the line to remove from your `kustomization.yaml`

Information about licenses from the [SAS Viya Platform Operations Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=k8sag&docsetTarget=n14rkqa3cycmd0n1ub50k47x7lbb.htm)

Note, these steps are only applicable for updating your license file, if you are going to be updating the SAS deployment or including additional products in your order we recommend that your perform your update manually. See this note in the [README](https://github.com/sassoftware/viya4-deployment#updating-sas-viya-manually)

## Tagging the AWS EC2 Load Balancers

### Symptom:

The EC2 Load Balancer that get provisioned dynamically by AWS during the baseline install phase of viya4-deployment when `ingress-nginx` is installed does not have the desired tags associated with it.

### Solution:

Based on this [Network Load Balancing documentation](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html) from AWS, you can set the `service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags` annotation your `ingress-nginx` configuration to customize the tags for your load balancer. To do this in the context of viya4-deployment, perform the following steps.

1. In your `ansible-vars.yaml` file, define `INGRESS_NGINX_CONFIG` and provide it with your own configuration values.
   * If you want to use the defaults that viya4-deployment uses, you can just copy the `INGRESS_NGINX_CONFIG` variable, and it's default configuration from here: https://github.com/sassoftware/viya4-deployment/blob/main/roles/baseline/defaults/main.yml. If you are copying it from this file, you will need to update the `loadBalancerSourceRanges` value within the configuration yourself.
2. Underneath the `controller.service.annotations` stanza in the configuration, you will need to add the following key,`service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags` and give it in values in the form of `"tagname1=tagvalue1,tagname2=tagvalue2"`. See the example below where I add the tags `mytag=foo` and `resourceowner="johnsmith"`
    ```yaml
    # defined in ansible-vars.yaml
    INGRESS_NGINX_CONFIG:
      controller:
        service:
          externalTrafficPolicy: Local
          sessionAffinity: None
          loadBalancerSourceRanges: ["0.0.0.0/0"] # you will need to update this for your own environment
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: "mytag=foo,resourceowner=johnsmith"
        config:
          use-forwarded-headers: "false"
          hsts-max-age: "63072000"
          hide-headers: Server,X-Powered-By
        tcp: {}
        udp: {}
        lifecycle:
          preStop:
            exec:
              command: [/bin/sh, -c, sleep 5; /usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf -s quit; while pgrep -x nginx; do sleep 1; done]
        terminationGracePeriodSeconds: 600
    ```
3. When the `baseline,install` ansible tasks are run and `ingress-nginx` is installed, the EC2 Load Balancer that gets provisioned by AWS will have those tags you specified.


## Deploying with cadence versions > 2024.06 without creating the external PostgreSQL SharedServices database

### Symptom

While deploying with a cadence version >= 2024.06 AND:

* you are targeting an IaC-provisioned cluster with an External PostgreSQL Database Server
* you didn't create the SharedServices database prior to running viya4-deployment

most pods will fail to initialize. The following error message can be found in the sas-data-server-operator pod:

```bash
$ kubectl logs deployment/sas-data-server-operator
{
  "level":"error",
  "source":"sas-data-server-operator-65c874585-xwzgr",
  "messageParameters":{
    "p1":"failed to connect to `host=example-default-flexpsql.postgres.database.azure.com user=pgadmin database=SharedServices`: server error (FATAL: database \"SharedServices\" does not exist (SQLSTATE 3D000))"
  },
  "messageKey":"failed to initialize database, got error %v",
  "message":"failed to initialize database, got error %v"
}
{
  "level":"error",
  "source":"sas-data-server-operator-65c874585-xwzgr",
  "messageKey":"Reconciler error",
  "properties":{
    "error":"database server is external and cannot connect to the SAS database",
    "caller":"logr/logr.go:49"
  },
  "attributes":{
    "DataServer":{
      "name":"sas-platform-postgres",
      "namespace":"deploy"
    },
  },
  "message":"Reconciler error"
}

```

### Solution

Due to changes in the sas-data-server-operator, the SharedServices database is not created automatically during the initial deployment of the SAS Viya platform. Instead, you must manually create it before you start the SAS Viya platform deployment

For more information, please refer to the [External Postgres Requirements](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#p1wq8ouke3c6ixn1la636df9oa1u) documentation.
