# SAS Viya 4 Deployment

## Overview

This project contains Ansible code that creates a baseline cluster in an existing Kubernetes environment for use with the SAS Viya platform, generates the manifest for a SAS Viya platform software order, and then deploys that order into the specified Kubernetes environment. Here is a list of tasks that this tool can perform: 

- Prepare Kubernetes cluster
  - Deploy [ingress-nginx](https://kubernetes.github.io/ingress-nginx)
  - Deploy [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) for PVs
  - Deploy [cert-manager](https://github.com/jetstack/cert-manager) for TLS
  - Deploy [metrics-server](https://github.com/bitnami/charts/tree/master/bitnami/metrics-server/) (AWS only)
  - Deploy [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) (AWS only)
  - Manage storageClass settings
  
- Deploy the SAS Viya Platform
  - Retrieve the deployment assets using [SAS Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
  - Retrieve cloud configuration from tfstate (if using a SAS Viya 4 IaC project)
  - Run the [kustomize](https://github.com/kubernetes-sigs/kustomize) process and deploy the SAS Viya platform
  - Create affinity rules such that processes are targeted to appropriately labeled nodes
  - Create pod disruption budgets for each service such that cluster maintenance will not let the last instance of a service go down (during a node maintenance operation, for example)
  - Use kustomize to mount user private (home) directories and data directories on CAS nodes and on compute server instances
  - Deploy [SAS Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
  - Deploy MPP or SMP CAS servers

- Manage SAS Viya Platform Deployments
  - Organize and persist configuration for any number of SAS Viya platform deployments across namespaces, clusters, or cloud providers.

- SAS Viya with SingleStore Deployment
  - SingleStore is a cloud-native database designed for data-intensive applications. See the [SAS Viya with SingleStore Documentation](./docs/user/SingleStore.md) for details.

## Prerequisites

Use of these tools requires operational knowledge of the following technologies: 

- [Ansible](https://docs.ansible.com/ansible/latest/user_guide/index.html#getting-started)
- [Docker](https://www.docker.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)
- Your selected cloud provider

### Technical Prerequisites

- [Ansible and Docker dependencies](docs/user/Dependencies.md)

### Infrastructure Prerequisites

The viya4-deployment playbook requires some infrastructure.

#### Kubernetes Cluster

You can either bring your own Kubernetes cluster or use one of the SAS Viya 4 IaC projects to create a cluster using Terraform scripts:
  - [SAS Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws)
  - [SAS Viya 4 IaC for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure)
  - [SAS Viya 4 IaC for Google Cloud](https://github.com/sassoftware/viya4-iac-gcp)


#### Storage

A file server that uses the network file system (NFS) protocol is the minimum requirement for the SAS Viya platform. You can either use one of the SAS Viya 4 IaC projects to create the required storage or bring your own Kubernetes storage. If you use the SAS Viya 4 IaC projects to create an NFS server VM and a jump box (bastion server) VM, the information can be passed in to viya4-deployment so that the required directory structures discussed in the next sections are created automatically. If you are bringing your own NFS-compliant server, the following NFS exports folder structure must be created prior to running viya4-deployment: 

  ```bash
  <export_dir>        <- NFS export path
    /pvs              <- location for persistent volumes
    /<namespace>      <- folder per namespace
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
      /astores        <- location for astores
  ```


#### Jump Box Virtual Machine

The jump box or bastion server can manage NFS folders if you provide SSH access to it. The jump box must have the NFS storage mounted to it at `<JUMP_SVR_RWX_FILESTORE_PATH>`. If you want to manage the NFS server yourself, the jump box is not required. Here is the required folder structure for the jump box:

  ```bash
  <JUMP_SVR_RWX_FILESTORE_PATH>     <- mounted NFS export
    /pvs                            <- location for persistent volumes
    /<namespace>                    <- folder per namespace
      /bin                          <- location for open source directories
      /data                         <- location for SAS and CAS data
      /homes                        <- location for user home directories to be mounted
      /astores                      <- location for ASTORES
  ```

## Getting Started

### Clone this Project

Run the following commands in a terminal session:

```bash
# clone this repository
git clone https://github.com/sassoftware/viya4-deployment

# move to directory
cd viya4-deployment
```

### Authenticating Ansible to Access Cloud Provider

See [Ansible Cloud Authentication](./docs/user/AnsibleCloudAuthentication.md) for details.

**NOTE:** At this time, additional setup is only required for Google Cloud with external PostgreSQL.

### Customize Input Values

The playbook uses Ansible variables for configuration. SAS recommends that you encrypt both this file and the other configuration files (sitedefault, kubeconfig, and tfstate) using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

#### Ansible Vars File

The Ansible vars.yaml file is the main configuration file. Create a file named ansible-vars.yaml to specify values for any input variables. Example variable definition files are provided in the `./examples` folder. For more details on the supported variables, refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

#### (Optional) Sitedefault File

The value is the path to a standard SAS Viya platform sitedefault file. If none is supplied, the example [sitedefault.yaml](examples/sitedefault.yaml) file is used. A sitedefault file is not required for a SAS Viya platform deployment.

#### Kubeconfig File

The Kubernetes access configuration file. If you used one of the SAS Viya 4 IaC projects to provision your cluster, this value is not required.

If you used the [viya4-iac-gcp](https://github.com/sassoftware/viya4-iac-gcp) project to create a provider based kubeconfig file to access your GKE cluster, refer to [kubernetes configuration file types](./docs/user/Kubeconfig.md) for instructions on using a Google Cloud provider based kubeconfig file with the viya4-deployment project.

#### Terraform State File

If you used a SAS Viya 4 IaC project to provision your cluster, you can provide the resulting tfstate file to have the kubeconfig and other settings auto-discovered. The [ansible-vars-iac.yaml](examples/ansible-vars-iac.yaml) example file shows the values that must be set when using the SAS Viya 4 IaC integration.

The following information is parsed from the integration:

- Cloud
  - PROVIDER
  - PROVIDER_ACCOUNT
  - CLUSTER_NAME
  - Cloud NAT IP address
- RWX Filestore
  - V4_CFG_RWX_FILESTORE_ENDPOINT
  - V4_CFG_RWX_FILESTORE_PATH
- JumpBox
  - JUMP_SVR_HOST
  - JUMP_SVR_USER
  - JUMP_SVR_RWX_FILESTORE_PATH
- Postgres
  - V4_CFG_POSTGRES_SERVERS (if postgres deployed)
- Cluster
  - KUBECONFIG
  - V4_CFG_CLUSTER_NODE_POOL_MODE
  - CLUSTER_AUTOSCALER_ACCOUNT
  - CLUSTER_AUTOSCALER_LOCATION
- Ingress
  - V4_CFG_INGRESS_MODE (from CLUSTER_API_MODE)

### Customize Deployment Overlays

The Ansible playbook in viya4-deployment fully manages the kustomization.yaml file. Users can make changes by adding custom overlays into subfolders under the `/site-config` folder. If this is the first time that you are running the playbook and plan to add customizations, create the following folder structure:

```bash
<base_dir>            <- parent directory
  /<cluster>          <- folder per cluster
    /<namespace>      <- folder per namespace
      /site-config    <- location for all customizations
        ...           <- folders containing user defined customizations
```

#### SAS Viya Platform Customizations

SAS Viya platform deployment customizations are automatically read in from folders under `/site-config`. To provide customizations, first create the folder structure detailed in the [Customize Deployment Overlays](#customize-deployment-overlays) section above. Then copy the desired overlays into a subfolder under `/site-config`. When you have completed these steps, you can run the viya4-deployment playbook. It will detect and add the overlays to the proper section of the kustomization.yaml file for the SAS Viya platform deployment.

**Note:** You do not need to modify the kustomization.yaml file. The playbook automatically adds the custom overlays to the kustomization.yaml file, based on the values you have specified.

For example:

- `/deployments` is the BASE_DIR
- The target cluster is named demo-cluster
- The namespace will be named demo-ns
- Add in a custom overlay that modifies the CAS server

```bash
  /deployments                        <- parent directory
    /demo-cluster                     <- folder per cluster
      /demo-ns                        <- folder per namespace
        /site-config                  <- location for all customizations
          /cas-server                 <- folder containing user defined customizations
            /my_custom_overlay.yaml   <- my custom overlay
 ```

The SAS Viya platform customizations that are managed by viya4-deployment are located under the [templates](https://github.com/sassoftware/viya4-deployment/tree/main/roles/vdm/templates) directory. These are purposely templatized and included there since they contain a set of customizations that are common or required for a functioning SAS Viya platform deployment. These particular files are configured via exposed variables that are documented within [CONFIG-VARS.md](docs/CONFIG-VARS.md) and do not need to be manually placed under `/site-config`.

#### OpenLDAP Customizations

The OpenLDAP setup that is described here is a temporary solution that enables you to add users and groups and to start using SAS Viya platform applications. The OpenLDAP server that is created using these instructions does not persist. It is created and destroyed within the SAS Viya platform namespace where it is created. To add users or groups that persist, follow the SAS documentation that describes how to [Configure an LDAP Identity Provider](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calids&docsetTarget=n1aw4xnkvwcddnn1mv8lxr2e4tu7.htm#p0spae4p1qoto3n1qpuzafcecxhh).

If the embedded OpenLDAP server is enabled, it is possible to change the users and groups that will be created. The required steps are similar to other customizations:
1. Create the folder structure detailed in the [Customize Deployment Overlays](#customize-deployment-overlays). 
2. Copy the `./examples/openldap` folder into the `/site-config` folder. 
3. Locate the openldap-modify-users.yaml file in the `/openldap` folder. 
4. Modify it to match the desired setup. 
5. Run the viya4-deployment playbook. It will use this setup when creating the OpenLDAP server.

**Note:** This method can only be used when you are first deploying the OpenLDAP server. Subsequently, you can either delete and redeploy the OpenLDAP server with a new configuration, or add users using `ldapadd`.</sub>

For example:

- `/deployments` is the BASE_DIR
- The cluster is named demo-cluster
- The namespace will be named demo-ns
- Add overlay with custom LDAP setup

```bash
  /deployments                          <- parent directory
    /demo-cluster                       <- folder per cluster
      /demo-ns                          <- folder per namespace
        /site-config                    <- location for all customizations
          /openldap                     <- folder containing user defined customizations
            /openldap-modify-users.yaml <- openldap overlay
 ```

## Creating and Managing Deployments

Create and manage deployments using one of the following methods: 

- running the [Docker container](docs/user/DockerUsage.md) (recommended)
- running [Ansible](docs/user/AnsibleUsage.md) directly on your workstation
  
### DNS

During the installation, an ingress load balancer can be installed for the SAS Viya platform and for the monitoring and logging stack. The host name for these services must be registered with your DNS provider in order to resolve to the LoadBalancer endpoint. This can be done by creating a record for each unique ingress controller host. 

However, when you are managing multiple SAS Viya platform deployments, creating these records can be time-consuming. In such a case, SAS recommends creating a DNS record that points to the ingress controller's endpoint. The endpoint might be an IP address or FQDN, depending on the cloud provider. Take these steps:

1. Create an A record or CNAME (depending on cloud provider) that resolves the desired host name to the LoadBalancer endpoint. 
2. Create a wildcard CNAME record that resolves to the record that you created in the previous step.

For example:

First, look up the ingress controller's LoadBalancer endpoint. The example below uses kubectl. This information can also be looked up in the cloud provider's admin portal.

```bash
$ kubectl get service -n ingress-nginx

NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.225.39   52.52.52.52      80:30603/TCP,443:32014/TCP   12d
ingress-nginx-controller-admission   ClusterIP      10.0.99.105   <none>           443/TCP                      12d
```

In the above example, the ingress controller's LoadBalancer endpoint is 52.52.52.52. So, we would create the following records:

- An A record (such as `example.com`) that points to the 52.52.52.52 address
- A wildcard CNAME (`*.example.com`) that points to example.com


#### SAS/CONNECT

When running the `viya` action with `V4_CFG_CONNECT_ENABLE_LOADBALANCER=true`, a separate loadbalancer service is created to allow external SAS/CONNECT clients to connect to the SAS Viya platform. You will need to register this LoadBalancer endpoint with your DNS provider such that the desired host name (for example, connect.example.com) points to the LoadBalancer endpoint.


### Updating SAS Viya Manually

Manual steps are required by the SAS software to update a SAS deployment in an existing cluster. As a result, viya4-deployment does not perform updates. The viya4-deployment tools can perform subsequent `viya,install` tasks if you are simply reapplying the same software order into the cluster.

If you have an existing deployment that you performed with the viya4-deployment project, take the following steps in order to update the SAS Viya platform:

- Follow the instructions in [Updating Software](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=k8sag&docsetTarget=titlepage.htm) in the SAS Viya Platform Operations Guide.
- You are expected to modify the steps that are described in the SAS Viya Platform Operations Guide to accommodate the slightly different directory structure 

### Troubleshooting

See the [Troubleshooting](./docs/Troubleshooting.md) page.

## Contributing

> We welcome your contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

- [SAS Viya Resource Guide](https://github.com/sassoftware/viya4-resource-guide)
- [SAS Viya 4 Infrastructure as Code (IaC) for Amazon Web Services (AWS)](https://github.com/sassoftware/viya4-iac-aws)
- [SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure)
- [SAS Viya 4 Infrastructure as Code (IaC) for Google Cloud](https://github.com/sassoftware/viya4-iac-gcp)
- [SAS Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
- [SAS Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
