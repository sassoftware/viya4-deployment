# SAS Viya Support for SingleStore

The SAS Viya platform provides an optional integration with SingleStore. SingleStore is a cloud-native database that is designed for data-intensive applications. A distributed, relational SQL database management system that features ANSI SQL support, SingleStore is known for speed in data ingest, transaction processing, and query processing.

## Requirements for SAS with SingleStore

If your SAS software order includes SAS with SingleStore, additional requirements apply to your deployment. The [_SAS Viya Platform Operations Guide_](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0jq6u1duu7sqnn13cwzecyt475u.htm#n0qs42c42o8jjzn12ib4276fk7pb) provides detailed information about requirements for a SingleStore-enabled deployment of the SAS Viya platform.

## Deploying SAS with SingleStore Using SAS Viya 4 Deployment

You can deploy SAS with SingleStore into a Kubernetes cluster in the following environments:
- Azure Kubernetes Service (AKS) in Microsoft Azure
- Elastic Kubernetes Service (EKS) in Amazon Web Services (AWS)
- Open Source Kubernetes on your own machines

## Cluster Provisioning for SAS with SingleStore

### Azure Kubernetes Service (AKS) Cluster in Microsoft Azure

The [SAS Viya 4 IaC for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure) GitHub project can automatically provision the required infrastructure components that support SAS with SingleStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-azure/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an AKS cluster that is suitable for deploying the SAS Viya platform and SingleStore.

### EKS Cluster in AWS

The [SAS Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws) GitHub project can automatically provision the required infrastructure components that support SAS with SingleStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-aws/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an EKS cluster that is suitable for deploying the SAS Viya platform and SingleStore.

### Open Source Kubernetes Cluster

The [SAS Viya 4 Infrastructure as Code (IaC) for Open Source Kubernetes](https://github.com/sassoftware/viya4-iac-k8s) GitHub project can automatically provision the required infrastructure components that support SAS with SingleStore deployments.
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-k8s/blob/main/examples/vsphere/sample-terraform-static-singlestore.tfvars) for Terraform configuration values that create an Open Source Kubernetes cluster that is suitable for deploying the SAS Viya platform and SingleStore.

## Customizing SingleStore Deployment Overlays

Choose the appropriate section below based on the cadence version of the SAS Viya platform and SingleStore that you are deploying.

### SAS Viya and SingleStore orders at stable:2023.10 and later

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `site-config` directory.

After running viya4-deployment with the setting `DEPLOY=false` in your ansible-vars.yaml file, locate the `sas-bases` directory, which is a peer to the `site-config` directory underneath your SAS Viya platform deployment's <base_dir>.

Complete each step under the "SingleStore Cluster Definition" heading in the "SAS SingleStore Cluster Operator" README file in order to configure your SAS with SingleStore deployment, noting the following exceptions. The README file is located at `$deploy/sas-bases/examples/sas-singlestore/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_singlestore_cluster_operator.htm` (for HTML format).

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

- Set `DEPLOY=true` in your ansible-vars.yaml file.

- Run viya4-deployment with the "viya, install" tags to deploy SAS with SingleStore into your cluster.

### SAS Viya and SingleStore orders at LTS:2023.03 and earlier

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `/site-config` directory.

After running viya4-deployment with the setting `DEPLOY=false` in your ansible-vars.yaml file, locate the `sas-bases` directory, which is a peer to the `site-config` directory underneath your SAS Viya platform deployment's <base_dir>.

Complete each step under the "SingleStore Cluster Definition" heading in the "SAS SingleStore Cluster Operator" README file in order to configure your SAS with SingleStore deployment, noting the following exceptions. The README file is located at `$deploy/sas-bases/examples/sas-singlestore/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_singlestore_cluster_operator.htm` (for HTML format).

- Complete steps 1 and 2 in the `sas-bases/examples/sas-singlestore/README.md` file.

- Complete Step 2a below:

  2a. Copy `$deploy/sas-bases/components/sas-singlestore` into the `$deploy/site-config/sas-singlestore/components` directory.

- Complete steps 3 and 4 in the "SAS SingleStore Cluster Operator" README file.

- Skip step 5 in the "SAS SingleStore Cluster Operator" README file. The viya4-deployment playbook will automatically add the SingleStore component and the overlays to the base kustomization.yaml file that you have copied to the `site-config` directory in the final step.

- Complete the remaining steps from the  "SAS SingleStore Cluster Operator" README file. Then set `DEPLOY=true` in your ansible-vars.yaml file.

- Run viya4-deployment with the "viya, install" tags to deploy SAS with SingleStore into your cluster.
