# SAS Viya Support for SingleStore

The SAS Viya platform provides an optional integration with SingleStore. SingleStore is a cloud-native database that is designed for data-intensive applications. A distributed, relational SQL database management system that features ANSI SQL support, SingleStore is known for speed in data ingest, transaction processing, and query processing.

## Requirements for SAS SpeedyStore

If your SAS software order includes SAS SpeedyStore, additional requirements apply to your deployment. The [_SAS Viya Platform Operations Guide_](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0jq6u1duu7sqnn13cwzecyt475u.htm#n0qs42c42o8jjzn12ib4276fk7pb) provides detailed information about requirements for a SingleStore-enabled deployment of the SAS Viya platform.

## Deploying SAS SpeedyStore Using SAS Viya 4 Deployment

You can deploy SAS SpeedyStore into a Kubernetes cluster in the following environments:
- Azure Kubernetes Service (AKS) in Microsoft Azure
- Elastic Kubernetes Service (EKS) in Amazon Web Services (AWS)
- Open Source Kubernetes on your own machines

## Cluster Provisioning for SAS SpeedyStore

### Azure Kubernetes Service (AKS) Cluster in Microsoft Azure

The [SAS Viya 4 IaC for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-azure/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an AKS cluster that is suitable for deploying the SAS Viya platform and SingleStore.

### EKS Cluster in AWS

The [SAS Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-aws/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an EKS cluster that is suitable for deploying the SAS Viya platform and SingleStore.

### Open Source Kubernetes Cluster

The [SAS Viya 4 Infrastructure as Code (IaC) for Open Source Kubernetes](https://github.com/sassoftware/viya4-iac-k8s) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-k8s/blob/main/examples/vsphere/sample-terraform-static-singlestore.tfvars) for Terraform configuration values that create an Open Source Kubernetes cluster that is suitable for deploying the SAS Viya platform and SingleStore.

## Customizing SingleStore Deployment Overlays

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `site-config` directory.

After running viya4-deployment with the setting `DEPLOY=false` in your ansible-vars.yaml file, locate the `sas-bases` directory, which is a peer to the `site-config` directory underneath your SAS Viya platform deployment's <base_dir>.

Complete each step under the "SingleStore Cluster Definition" heading in the "SAS SingleStore Cluster Operator" README file in order to configure your SAS SpeedyStore deployment, noting the following exceptions. The README file is located at `$deploy/sas-bases/examples/sas-singlestore/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_singlestore_cluster_operator.htm` (for HTML format).

- Complete steps 1 and 2 in the "SAS SingleStore Cluster Operator" README file.

- After you complete step 2, complete these additional steps 2a, 2b, 2c, and 2d:

  2a. Create the `$deploy/site-config/sas-singlestore/component` subdirectory.

  2b. Copy the `$deploy/sas-bases/components/sas-singlestore/` subdirectory into the `$deploy/site-config/sas-singlestore/component/` subdirectory.

  2c. Create the `$deploy/site-config/sas-singlestore/examples` subdirectory.

  2d. Move the `sas-singlestore-secret.yaml` file and the `kustomization.yaml` file located in the `$deploy/site-config/sas-singlestore` subdirectory to the `$deploy/site-config/sas-singlestore/examples` subdirectory. 

- Complete steps 3 and 4 in the "SAS SingleStore Cluster Operator" README file.

- Skip step 5 in the "SAS SingleStore Cluster Operator" README file. The viya4-deployment playbook will automatically add the SingleStore component and the overlays to the base `kustomization.yaml` file in the final step.

- In step 6 of the "SAS SingleStore Cluster Operator" README file, if you do NOT want to override the cluster OS configuration, continue to the next step. If you do want to override the cluster OS configuration, copy the `$deploy/sas-bases/examples/sas-singlestore-osconfig/sas-singlestore-osconfig.yaml` file to the `$deploy/site-config/sas-singlestore` subdirectory. Refer to the "SAS SingleStore Cluster OS Configuration" README file for additional guidance. The "SAS SingleStore Cluster OS Configuration" README file is located at `$deploy/sas-bases/examples/sas-singlestore-osconfig/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_singlestore_cluster_os_configuration.htm` (for HTML format).

  The contents of your `$deploy/site-config/sas-singlestore` subdirectory should now look like this:

```markdown
.
├── component/sas-singlestore
│   ├── kustomization.yaml
│   ├── kustomizeconfig.yaml
│   ├── sas-singlestore-cluster.yaml
│   ├── secret.yaml
│   └── transformers.yaml
├── examples
│   ├── kustomization.yaml
│   └── sas-singlestore-secret.yaml
├── README.md
├── sas-singlestore-cluster-config.yaml
└── sas-singlestore-osconfig.yaml           (present only if you did NOT skip step 6 above)
```

- #### Additional Configuration for AWS LoadBalancer Service

  Default settings in AWS can easily lead to the creation of IP addresses for the SingleStore LoadBalancer service that are accessible from outside of your VPC.
  
  By default, the SAS SpeedyStore deployment sets the scheme of the SingleStore LoadBalancer service to "internal," which is private and inaccessible from outside the cluster. The IP addresses for each of the two SingleStore service ports default to "internal" because the aws-load-balancer-scheme annotation defaults to "internal": aws-load-balancer-scheme: internal
  
  However, SAS has determined that AWS does not honor the annotation without additional configuration. As a result, your default LoadBalancer service is likely to be accessible from outside the cluster (that is, set to "internet-facing"). At least one of two specific AWS features, EKS Auto Mode or the aws-load-balancer-controller, must be enabled before AWS can honor the default "internal" annotation and secure the IP address.
  
  For more information, see the following documents:
  
  1. [Use Service Annotations to configure Network Load Balancers](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html)
  2. [Create a cluster with Amazon EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/create-auto.html)
  3. [Enable EKS Auto Mode on an existing cluster](https://docs.aws.amazon.com/eks/latest/userguide/auto-enable-existing.html)
  4. [Deploy an AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/)

- Set `DEPLOY=true` in your ansible-vars.yaml file.

- Run viya4-deployment with the "viya, install" tags to deploy SAS SpeedyStore into your cluster.
