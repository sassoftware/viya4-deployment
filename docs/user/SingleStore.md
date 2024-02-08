# SAS Viya Support for SingleStore

The SAS Viya platform provides an optional integration with SingleStoreDB. SingleStoreDB is a cloud-native database that is designed for data-intensive applications. A distributed, relational SQL database management system that features ANSI SQL support, SingleStoreDB is known for speed in data ingest, transaction processing, and query processing. 

## Requirements for SAS Viya with SingleStore

If your SAS software order included SAS Viya with SingleStore, additional requirements apply to your deployment. The SAS Viya Platform _IT Operations Guide_ provides detailed information about requirements for a SingleStore-enabled deployment of SAS Viya. You can access the guide [here](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0jq6u1duu7sqnn13cwzecyt475u.htm#n0qs42c42o8jjzn12ib4276fk7pb).

## Deploying SAS Viya with SingleStore Using SAS Viya 4 Deployment

You can deploy SAS Viya with SingleStore into a Kubernetes cluster running under:
- Azure Kubernetes Service (AKS) in Microsoft Azure
- Elastic Kubernetes Service (EKS) in Amazon Web Services (AWS)
- Open Source Kubernetes on your own machines

## Cluster Provisioning for SAS Viya with SingleStore

### Azure Kubernetes Service (AKS) Cluster in Microsoft Azure

The [SAS Viya 4 IaC for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure) GitHub project can automatically provision the required infrastructure components that support SAS Viya with SingleStore deployments. 
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-azure/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an AKS cluster that is suitable for deploying SAS Viya and SingleStore.

### EKS Cluster in AWS

The [SAS Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws) GitHub project can automatically provision the required infrastructure components that support SAS Viya with SingleStore deployments. 
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-aws/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an EKS cluster that is suitable for deploying SAS Viya and SingleStore.

### Open Source Kubernetes Cluster

The [SAS Viya 4 Infrastructure as Code (IaC) for Open Source Kubernetes](https://github.com/sassoftware/viya4-iac-k8s) GitHub project can automatically provision the required infrastructure components that support SAS Viya with SingleStore deployments. 
Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-k8s/blob/main/examples/vsphere/sample-terraform-static-singlestore.tfvars) for Terraform configuration values that create an Open Source Kubernetes cluster that is suitable for deploying SAS Viya and SingleStore.

## Customizing SingleStore Deployment Overlays

Choose the appropriate section below based on which cadence version of SAS Viya and SingleStore that you are deploying.

### SAS Viya and SingleStore orders at stable:2023.10 and later

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `/site-config` directory.

After running viya4-deployment with the setting `DEPLOY=false` in your ansible-vars.yaml file, locate the `sas-bases/` directory, which is a peer to the `site-config/` directory underneath your SAS deployment's <base_dir>.

Complete each step under the **SingleStore Cluster Definition** heading in the `sas-bases/examples/sas-singlestore/README.md` file in order to configure your SAS Viya with SingleStore deployment, noting the following exceptions:

- Complete Steps 1 and 2 in the `sas-bases/examples/sas-singlestore/README.md` file.

- Complete Steps 2a, 2b, 2c and 2d below:

  2a. Create the `$deploy/site-config/sas-singlestore/component` subdirectory.

  2b. Copy the `sas-bases/components/sas-singlestore/` subdirectory into the `$deploy/site-config/sas-singlestore/component/` subdirectory.

  2c. Create the `$deploy/site-config/sas-singlestore/examples` subdirectory.

  2d. Move the `sas-singlestore-secret.yaml` file and the `kustomization.yaml` file located in the `$deploy/site-config/sas-singlestore` subdirectory to the `$deploy/site-config/sas-singlestore/examples` subdirectory. 

- Complete Steps 3 and 4 in the `sas-bases/examples/sas-singlestore/README.md` file.

- Skip Step 5 in the `sas-bases/examples/sas-singlestore/README.md` file, the viya4-deployment playbook will automatically add the SingleStore component and the overlays to the base `kustomization.yaml` file in the final step.

- In Step 6 of the `sas-bases/examples/sas-singlestore/README.md`, if you do NOT wish to override the cluster OS configuration, continue to the next step. If you do wish to override the cluster OS configuration, copy the `$deploy/sas-bases/examples/sas-singlestore-osconfig/sas-singlestore-osconfig.yaml` file to the `$deploy/site-config/sas-singlestore` subdirectory. Refer to the `sas-bases/examples/sas-singlestore-osconfig/README.md` for additional guidance.

The contents of your `$deploy/site-config/sas-singlestore` subdirectory should now look like this:

```markdown
.
├── component/sas-singlestore
│   ├── kustomization.yaml
│   ├── kustomizeconfig.yaml
│   ├── sas-singlestore-cluster.yaml
│   ├── secret.yaml
│   └── transformers.yaml
├── example
│   ├── kustomization.yaml
│   └── sas-singlestore-secret.yaml
├── README.md
├── sas-singlestore-cluster-config.yaml
└── sas-singlestore-osconfig.yaml           (present only if you did not skip Step 6 above)
```

- Set `DEPLOY=true` in your ansible-vars.yaml file. 

- Then run viya4-deployment with the "viya, install" tags to deploy SAS Viya with SingleStore into your cluster.


### SAS Viya and SingleStore orders at LTS:2023.03 and earlier

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `/site-config` directory.

After running viya4-deployment with the setting `DEPLOY=false` in your ansible-vars.yaml file, locate the `sas-bases/` directory, which is a peer to the `site-config/` directory underneath your SAS deployment's <base_dir>.

Complete each step under the **SingleStore Cluster Definition** heading in the `sas-bases/examples/sas-singlestore/README.md` file in order to configure your SAS Viya with SingleStore deployment, noting the following exceptions:

- Complete Steps 1 and 2 in the `sas-bases/examples/sas-singlestore/README.md` file.

- Complete Step 2a below:

    2a. Copy `$deploy/sas-bases/components/sas-singlestore` into the `$deploy/site-config/sas-singlestore/components` directory.

- Complete Steps 3 and 4 in the `sas-bases/examples/sas-singlestore/README.md` file.  

- Skip Step 5 in the `sas-bases/examples/sas-singlestore/README.md` file. The viya4-deployment playbook will automatically add the SingleStore component and the overlays to the base kustomization.yaml file that you have copied to the `/site-config` directory in the final step.

- Complete the remaining steps from the  `sas-bases/examples/sas-singlestore/README.md` for SingleStore, and set `DEPLOY=true` in your ansible-vars.yaml file. 

- Then run viya4-deployment with the "viya, install" tags to deploy SAS Viya with SingleStore into your cluster.
