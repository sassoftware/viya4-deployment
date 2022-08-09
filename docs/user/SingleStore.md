# SAS Viya Support for SingleStore

SAS Viya supports SingleStore. SingleStore is a cloud-native database designed for data-intensive applications. A distributed, relational, SQL database management system that features ANSI SQL support, it is known for speed in data ingest, transaction processing, and query processing. 

## Requirements for a SingleStore SAS Viya deployment

If your SAS software order included SAS Viya with SingleStore, there are additional requirements that may apply to your deployment. The SAS Viya _IT Operations Guide_ provides detailed information about requirements for a SingleStore enabled deployment of SAS Viya. Access it [here](https://documentation.sas.com/doc/en/itopscdc/default/itopssr/n0jq6u1duu7sqnn13cwzecyt475u.htm#n0qs42c42o8jjzn12ib4276fk7pb)

## Deploying SingleStore with SAS Viya Deployment

You can deploy SAS Viya with SingleStore into a Kubernetes cluster that is running in Microsoft Azure. The [SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure) GitHub project can automatically provision the required infrastructure components that support SAS Viya with SingleStore deployments. Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-azure/blob/singlestore/examples/sample-input-singlestore.tfvars) for terraform configuration values that create an Azure cluster suitable for deploying Viya and SingleStore to.

## Customizing SingleStore Deployment Overlays

Refer to the SAS Viya Deployment instructions [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and the [SAS Viya Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-customizations) section for information on how users can make changes to their deployment by adding custom overlays into subfolders under the `/site-config` folder.

After running SAS Viya Deployment with the setting DEPLOY=false in your ansible-vars.yaml file, locate the `sas-bases/` folder which is a peer to the `site-config/` folder underneath your deployments <base_dir>.

Follow each step under the `SingleStore Cluster Definition` heading in the `sas-bases/examples/sas-singlestore/README.md` file to configure your SingleStore deployment noting the exceptions below:

Add the new Step 1a after Step 1.

1a. Copy `$deploy/sas-bases/components/sas-singlestore` into `$deploy/site-config/sas-singlestore/component`.

Skip Step 3.  The SAS Viya Deployment playbook will automatically add the SingleStore component and overlays to the base kustomization.yaml file that you have copied to `site-config/` and edited per the README.md file steps.

After completing the README.md steps for SingleStore, set DEPLOY=true in your ansible-vars.yaml file and run SAS Viya Deployment with the "viya, install" tags to deploy Viya with SingleStore into your cluster.