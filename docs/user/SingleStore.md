# SAS Viya Support for SingleStore

The SAS Viya platform provides an optional integration with SingleStore, which is licensed as SAS SpeedyStore. SingleStore is a cloud-native database that is designed for data-intensive applications. A distributed, relational SQL database management system that features ANSI SQL support, SingleStore is known for speed in data ingest, transaction processing, and query processing.

## Requirements for SAS SpeedyStore

If your SAS software order includes SAS SpeedyStore, additional requirements apply to your deployment. The [_SAS Viya Platform Operations Guide_](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=n0jq6u1duu7sqnn13cwzecyt475u.htm#n0qs42c42o8jjzn12ib4276fk7pb) provides detailed information about requirements for a SingleStore-enabled deployment of the SAS Viya platform.

## Deploying SAS SpeedyStore Using SAS Viya 4 Deployment

This document describes how to configure and deploy SAS SpeedyStore in a SAS Viya platform.

The procedure in this document is specific to the viya4-deployment (DaC) layout and differs from the generic SingleStore Operator workflow used when deploying with other deployment methods such as the SAS Deployment Operator.

You can deploy SAS SpeedyStore into a Kubernetes cluster in the following environments:
- Azure Kubernetes Service (AKS) in Microsoft Azure
- Elastic Kubernetes Service (EKS) in Amazon Web Services (AWS)
- Open Source Kubernetes on your own machines
- Google Kubernetes Engine (GKE) in Google Cloud and Google Distributed Cloud

## Cluster Provisioning for SAS SpeedyStore

### Azure Kubernetes Service Cluster in Microsoft Azure

The [SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.

Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-azure/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an AKS cluster suitable for deploying SAS SpeedyStore.

### EKS Cluster in AWS

The [SAS Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.

Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-aws/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create an EKS cluster suitable for deploying SAS SpeedyStore.

### Open Source Kubernetes Cluster

The [SAS Viya 4 IaC for Open Source Kubernetes](https://github.com/sassoftware/viya4-iac-k8s) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.

Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-k8s/blob/main/examples/vsphere/sample-terraform-static-singlestore.tfvars) for Terraform configuration values that create an Open Source Kubernetes cluster suitable for deploying SAS SpeedyStore.

### Google Kubernetes Engine Cluster in Google Cloud and Google Distributed Cloud

The [SAS Viya 4 IaC for Google Cloud and Google Distributed Cloud](https://github.com/sassoftware/viya4-iac-gcp) GitHub project can automatically provision the required infrastructure components that support SAS SpeedyStore deployments.

Refer to the [SingleStore sample input file](https://github.com/sassoftware/viya4-iac-gcp/blob/main/examples/sample-input-singlestore.tfvars) for Terraform configuration values that create a GKE cluster suitable for deploying SAS SpeedyStore.

## Prepare the Deployment Workspace

Before you configure SAS SpeedyStore, complete the normal viya4-deployment setup and set `DEPLOY=false` in your `ansible-vars.yaml` file.

After you run viya4-deployment with `DEPLOY=false`, locate the following directories beneath your deployment base directory:

- `sas-bases`
- `site-config`

The `sas-bases` directory contains the example manifests and components provided by SAS. The `site-config` directory is where you add your deployment-specific overlays for SAS SpeedyStore.

Refer to the viya4-deployment [Getting Started](https://github.com/sassoftware/viya4-deployment#getting-started) and [SAS Viya Platform Customizations](https://github.com/sassoftware/viya4-deployment#sas-viya-platform-customizations) documentation if you need information about how to make changes to your deployment by adding custom overlays into subdirectories under the `site-config` directory.

This section describes the required DaC-specific configuration for SAS SpeedyStore.

## Configure the SingleStore Cluster

The configuration of the SingleStore cluster is site-specific. To configure a SingleStore cluster for your deployment:

1. Create the DaC-specific SingleStore configuration directories.

   - `$deploy/site-config/sas-singlestore`
   - `$deploy/site-config/sas-singlestore/component`
   - `$deploy/site-config/sas-singlestore/examples`

2. Copy the `$deploy/sas-bases/components/sas-singlestore/` directory into `$deploy/site-config/sas-singlestore/component/`.

3. Copy the files from `$deploy/sas-bases/examples/sas-singlestore/` into `$deploy/site-config/sas-singlestore/`.

   If you are not configuring backups, remove the `backup/` directory from the copied example tree.

   If you are configuring backups, keep exactly one backup provider and authentication path and remove all other backup paths. For example, for AWS backups using IRSA, keep only `$deploy/site-config/sas-singlestore/backup/aws/irsa/` and remove all other backup subdirectories.

4. Move the `sas-singlestore-secret.yaml` file and the `kustomization.yaml` file into the `examples` directory.

   Move the following files:

   - `$deploy/site-config/sas-singlestore/sas-singlestore-secret.yaml` to `$deploy/site-config/sas-singlestore/examples/sas-singlestore-secret.yaml`
   - `$deploy/site-config/sas-singlestore/kustomization.yaml` to `$deploy/site-config/sas-singlestore/examples/kustomization.yaml`

5. Configure the secret file.

   Edit `$deploy/site-config/sas-singlestore/examples/sas-singlestore-secret.yaml` and replace the following values:

   - Replace `{{ LICENSE-CODE }}` with your SingleStore license code.
   - Replace `{{ HASHED-ADMIN-PASSWORD }}` with the hashed admin password for the admin account.

   Use the following Python example to generate the hash:

   ```python
   from hashlib import sha1
   print("*" + sha1(sha1('secretpass'.encode('utf-8')).digest()).hexdigest().upper())
   ```

    In the python code, replace `secretpass` with your desired admin password, and then paste the resulting output into the `sas-singlestore-secret.yaml` file, replacing the string `{{ HASHED-ADMIN-PASSWORD }}`. The hashed password contains an initial asterisk that must be included.

6. Customize the cluster configuration.

   a. Override the default cluster settings, such as the number of leaf nodes, storage class, amount of storage allocated to each node type, or aggregator settings.

      Edit `$deploy/site-config/sas-singlestore/sas-singlestore-cluster-config.yaml`

      In the following example, the leaf node definition is modified to create four leaf nodes, each with 750 GB of storage, using a scaling height of 1 (defined as 8 vCPU cores and 32 GB of RAM) and the `managed` storage class. You may also want to perform similar alterations to the aggregatorSpec.

      Refer to the [SingleStore Cluster Scaling Document](https://docs.singlestore.com/db/latest/reference/singlestore-operator-reference/scale-a-cluster) for more information.

      ```yaml
      - op: replace
        path: /spec/leafSpec/count
        value: 4
      - op: replace
        path: /spec/leafSpec/height
        value: 1
      - op: replace
        path: /spec/leafSpec/storageGB
        value: 750
      - op: replace
        path: /spec/leafSpec/storageClass
        value: managed
      ```

   b. Activate exactly one cloud profile for your deployment.

      The `sas-singlestore-cluster-config.yaml` file includes cloud provider-specific profile blocks.

      - Azure profile settings are enabled by default.
      - For AWS deployments, choose either the AWS EKS IPv4 profile or the AWS EKS IPv6 profile.
      - The AWS EKS IPv6 profile is for new IPv6 installations only.
      - For AWS, Google Cloud, or Open Source Kubernetes deployments, comment out the Azure profile lines and uncomment the matching provider-specific profile lines.
      - Do not enable more than one provider profile at the same time.

7. Configure load balancer source ranges if required.

   To allow certain source ranges to access the load balancer, you must override the `loadBalancerSourceRanges` cluster attribute to configure optional firewall rules. Refer to the [SingleStore Advanced Service Configuration](https://docs.singlestore.com/db/latest/reference/singlestore-operator-reference/advanced-service-configuration) for more information.  Define all source ranges in CIDR notation. For IPv6 profiles, include IPv6 CIDR ranges. For dual-stack deployments, include both IPv4 and IPv6 CIDR ranges. The following examples demonstrate defining the load balancer source ranges:

   * Multiple IPv4 source ranges
   * A single IPv4 source range
   * A single IPv6 source range
   * Mixed IPv4 and IPv6 source ranges (dual-stack)
   * No source range, using an empty array

   ```yaml
   - op: replace
     path: /spec/serviceSpec/loadBalancerSourceRanges
     value: [ 100.110.120.130/16, 200.210.220.230/28, {{ IP-RANGE }} ]

   ...
   - op: replace
     path: /spec/serviceSpec/loadBalancerSourceRanges
     value: [ 100.110.120.130/16 ]

   ...
   - op: replace
     path: /spec/serviceSpec/loadBalancerSourceRanges
     value: [ 2600:1f16:dfb:fd00::/56 ]

   ...
   - op: replace
     path: /spec/serviceSpec/loadBalancerSourceRanges
     value: [ 100.110.120.130/16, 2600:1f16:dfb:fd00::/56 ]

   ...
   - op: replace
     path: /spec/serviceSpec/loadBalancerSourceRanges
     value: []
   ```

8. Verify the DaC directory layout.

   After the files are moved and configured, your `$deploy/site-config/sas-singlestore` directory should look like this:

   ```markdown
   .
   ├── component
   │   └── sas-singlestore
   │       ├── kustomization.yaml
   │       ├── kustomizeconfig.yaml
   │       ├── sas-singlestore-cluster.yaml
   │       ├── secret.yaml
   │       └── transformers.yaml
   ├── examples
   │   ├── kustomization.yaml
   │   └── sas-singlestore-secret.yaml
   ├── README.md
   ├── sas-singlestore-cluster-config.yaml
   └── sas-singlestore-osconfig.yaml     (present only if you override the cluster OS configuration)
   ```

   The key DaC-specific conventions are:

   - The `component/` directory holds the copied SAS SingleStore component.
   - The `examples/` directory holds the secret and any SingleStore backup overlays.
   - The base `kustomization.yaml` is managed by the viya4-deployment playbook, so you do not add the component manually there.
   - Provider-specific SingleStore backup components are added to `$deploy/site-config/sas-singlestore/examples/kustomization.yaml`, not to the base deployment `kustomization.yaml`.

## Optional Cluster OS Configuration

Determine whether you need to override the cluster OS configuration. For more information, see the README file located at `$deploy/sas-bases/examples/sas-singlestore-osconfig/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/sas_speedystore_cluster_os_configuration.htm` (for HTML format).

If you do not need to override the cluster OS configuration, continue to the next section.

If you do need to override the cluster OS configuration, copy `$deploy/sas-bases/examples/sas-singlestore-osconfig/sas-singlestore-osconfig.yaml` to `$deploy/site-config/sas-singlestore/sas-singlestore-osconfig.yaml`

After copying the `sas-singlestore-osconfig.yaml` file, refer to the "SAS SpeedyStore Cluster OS Configuration" README file for additional guidance.

## Optional Backup Configuration

If you do not want to configure SingleStore backups, continue to the deployment section. For more information, see the README file located at `$deploy/sas-bases/examples/sas-singlestore/backup/README.md` (for Markdown format) or at `$deploy/sas-bases/docs/optional_sas_singlestore_backup_configuration.htm` (for HTML format).

If you do want to configure SingleStore backups, configure exactly one backup provider and one authentication path for your environment:

1. Copy the `$deploy/sas-bases/components/sas-singlestore-backup/` subdirectory into `$deploy/site-config/sas-singlestore/component/` directory.

2. Keep only the single backup provider path that applies to your environment under the `$deploy/site-config/sas-singlestore/backup` directory and remove all other backup paths before you move the backup directory.

   In the viya4-deployment layout, the valid provider paths are relative to `$deploy/site-config/sas-singlestore/` before the move to `examples/`:

   - `backup/aws/iam-user`
   - `backup/aws/irsa`
   - `backup/azure/account-key`

3. Edit the examples kustomization file.

   Add the selected provider-specific backup component to `$deploy/site-config/sas-singlestore/examples/kustomization.yaml`. Keep any existing content in the file (for example, `generators`) unchanged.

   Here is an example:
      ```yaml
   ...
   generators:
     - sas-singlestore-secret.yaml
   ...
   components:
     - backup/aws/irsa
   ```

4. Move the `backup` subdirectory from `$deploy/site-config/sas-singlestore/` to `$deploy/site-config/sas-singlestore/examples/`.

5. Verify the final layout.

   After the backup configuration is complete, keep only the selected provider path and remove all others. The source example set contains multiple provider directories, but a valid final configuration contains exactly one active backup path.

   For example, if you select `backup/aws/irsa`, your `$deploy/site-config/sas-singlestore` directory should look like this:

   ```markdown
   .
   ├── component
   │   ├── sas-singlestore
   │   │   ├── kustomization.yaml
   │   │   ├── kustomizeconfig.yaml
   │   │   ├── sas-singlestore-cluster.yaml
   │   │   ├── secret.yaml
   │   │   └── transformers.yaml
   │   └── sas-singlestore-backup
   │       ├── kustomization.yaml
   │       ├── kustomizeconfig.yaml
   │       ├── rolebinding.yaml
   │       ├── role.yaml
   │       └── service-account.yaml
   ├── examples
   │   ├── kustomization.yaml
   │   ├── sas-singlestore-secret.yaml
   │   └── backup
   │       ├── README.md
   │       └── aws
   │           └── irsa
   │               ├── kustomization.yaml
   │               └── ...
   ├── README.md
   ├── sas-singlestore-cluster-config.yaml
   └── sas-singlestore-osconfig.yaml       (present only if you override the cluster OS configuration)
   ```

## Additional Configuration for AWS LoadBalancer Service

Default AWS settings can result in the SingleStore LoadBalancer service receiving IP addresses that are accessible from outside of your VPC.

By default, the SAS SpeedyStore deployment configures the SingleStore LoadBalancer service with the internal scheme, which is private and inaccessible from outside the cluster. The IP addresses for each of the two SingleStore service ports also default to internal because the `aws-load-balancer-scheme` annotation defaults to `internal`.

However, SAS has determined that AWS does not always honor the annotation without additional configuration. In some environments, the default LoadBalancer service is created as `internet-facing` instead of `internal`. At least one of the following must be enabled before AWS can honor the default internal annotation:

- EKS Auto Mode
- AWS Load Balancer Controller

For more information, see:

1. [Use Service Annotations to configure Network Load Balancers](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html)
2. [Create a cluster with Amazon EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/create-auto.html)
3. [Enable EKS Auto Mode on an existing cluster](https://docs.aws.amazon.com/eks/latest/userguide/auto-enable-existing.html)
4. [Deploy an AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/)

## Deploy SAS SpeedyStore

After you complete the required SingleStore configuration and any optional OS and backup customizations:

- Set `DEPLOY=true` in your `ansible-vars.yaml` file.
- Run viya4-deployment with the `viya, install` tags.

This deploys SAS SpeedyStore into your cluster and applies the DaC-specific overlays configured in your `site-config/sas-singlestore` directory.
