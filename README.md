# SAS Viya 4 Deployment

## Overview

This project contains Ansible code that creates a baseline in an existing kubernetes environment for use with Viya 4+, generates the manifest for an order, and then can also deploy that order into the kubernetes environment specified. Here is a list of things this tool can do - 

- Prepare K8s cluster
  - Deploy [ingress-nginx](https://kubernetes.github.io/ingress-nginx)
  - Deploy [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) for PVs
  - Deploy [cert-manager](https://github.com/jetstack/cert-manager) if TLS to be configured
  - Deploy [metrics-server](https://github.com/bitnami/charts/tree/master/bitnami/metrics-server/)
  - Manage storageclass
  
- Deploy Viya
  - Retrieve the deployment assets using [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
  - Retrieve cloud configuration from tfstate if using a Viya 4 IaC project
  - Run the [kustomize](https://github.com/kubernetes-sigs/kustomize) process and deploy Viya
  - Create affinity rules such that processes are targeted to appropriately labeled nodes.
  - Create pod disruption budgets for each service such that cluster maintenance will not let the last instance of a service go down during a node maintenance operation for example.
  - kustomize such that data and homes directories are mounted on cas nodes and on compute server instances
  - Deploy [Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
  - Deploy MPP or SMP CAS servers

- Manage Viya Deployments
  - Organize and persist config for any number of Viya deployments across namespaces, cluster, or cloud providers.

## Prerequisites

### Operational knowledge of 

- [Ansible](https://docs.ansible.com/ansible/latest/user_guide/index.html#getting-started)
- [Docker](https://www.docker.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)
- Cloud Provider

### Technical

- [Ansible and docker dependencies](docs/user/Dependencies.md)

### Infrastructure

Prior to running this playbook some infrastructure needs to be in place

- Kubernetes cluster: You can either bring your own K8s cluster or use one of the Viya 4 IAC projects to create a cluster using terraform.
  - [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure)
  - [Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws)


- Storage: When using NFS based storage (like Azure NetApp or EFS), then the storage needs certain folders setup. There needs to be a PVs folder created under the export path. This is used for PVs. Additionally, a folder needs to be created for each cluster with sub-folders for bin, data, and homes. Below is the required NFS exports folder structure

  ```bash
  <export_dir>        <- NFS export path
    /pvs              <- location for persistent volumes
    /<namespace>      <- folder per namespace
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
      /astores        <- location for astores
  ```

- JumpBox: This tool can manage NFS folders if you provide ssh access to a JumpBox that has the NFS storage mounted to it at <JUMP_SVR_RWX_FILESTORE_PATH>. The Viya 4 IAC projects automate the needed NFS/JumpBox setup if desired. If you wish to manage the NFS server yourself, the JumpBox is not required. Below is the JumpBox folder structure

  ```bash
  <JUMP_SVR_RWX_FILESTORE_PATH>     <- mounted NFS export
    /pvs                            <- location for persistent volumes
    /<namespace>                    <- folder per namespace
      /bin                          <- location for open source directories
      /data                         <- location for SAS and CAS Data
      /homes                        <- location for user home directories to be mounted
      /astores                      <- location for astores
  ```

## Getting Started

### Clone this project

Run these commands in a Terminal session:

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-deployment

# move to directory
cd viya4-deployment
```

### Authenticating Ansible to access Cloud Provider

See [Ansible Cloud Authentication](./docs/user/AnsibleCloudAuthentication.md) for details.

**NOTE:** At this time, only required for GCP with external postgres

### Customize Input Values

The playbook uses ansible vars for configuration. It is recommended to encrypt both this file and the other configs (sitedefault, kubeconfig, and tfstate) using [ansible vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

#### Ansible Vars

The ansible vars file is the main configuration file. Create a file named ansible-vars.yaml to customize any input variable value. Example variable definition files are provided in the ./examples folder. For more details on the supported variables refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

#### Sitedefault

This is a normal VIYA sitedefault file. If none is supplied, the example [sitedefault.yaml](examples/sitedefault.yaml) will be used.

#### Kubeconfig

Kubernetes access config file. When integrating with SAS Viya 4 IaC projects, this value is not required.

#### Terraform state file

When integrating with SAS Viya 4 IaC projects, you can provide the tfstate file to have the kubeconfig and other setting auto-discovered. The [ansible-vars-iac.yaml](examples/ansible-vars-iac.yaml) example file shows the values that need to be set when using the iac integration.

This following information is parsed from the integration:

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
- Postgres (When V4_CFG_POSTGRES_TYPE is set to external)
  - V4_CFG_POSTGRES_ADMIN_LOGIN
  - V4_CFG_POSTGRES_PASSWORD
  - V4_CFG_POSTGRES_FQDN
  - V4_CFG_POSTGRES_CONNECTION_NAME
  - V4_CFG_POSTGRES_SERVICE_ACCOUNT

### Customize Deployment Overlays

viya4-deployment fully manages the kustomization.yaml file. Users can make changes by adding custom overlays into sub-folders under the site-config folder. If this is the first time running the tool and customizations will be provided, create the folder structure below.

```bash
<base_dir>            <- parent directory
  /<cluster>          <- folder per cluster
    /<namespace>      <- folder per namespace
      /site-config    <- location for all customizations
        ...           <- folders containing user defined customizations
```

#### Viya Customizations

Viya customizations are automatically read in from folders under site-config. To do so, first create the folder structure detailed in the [Customize Deployment Overlays](#customize-deployment-overlays) section above. Afterwards you can copy the desired overlays into a sub-folder under site-config. Once complete you can run the viya4-deployment tool and it will detect and add the overlays to the proper section in the kustomization.yaml

<sub> Note that you do not need to modify the kustomization.yaml. The tool will automatically add the custom overlays to the kustomization.yaml file.<sub>

For Example:

- /deployments is the BASE_DIR
- Cluster named demo-cluster
- Namespace will be named demo-ns
- Add in a custom overlay that modifies cas

```bash
  /deployments                        <- parent directory
    /demo-cluster                     <- folder per cluster
      /demo-ns                        <- folder per namespace
        /site-config                  <- location for all customizations
          /cas-server                 <- folder containing user defined customizations
            /my_custom_overlay.yaml   <- my custom overlay
 ```

#### Openldap Customizations

If the embedded openldap server is enabled, it is possible to change the users/groups that will be created. This can be done like any other customizations. First create the folder structure detailed in the [Customize Deployment Overlays](#customize-deployment-overlays). Then, copy the ./examples/openldap folder into the site-config folder. Inside the openldap folder is openldap-modify-users.yaml file. Modify it to match the desired setup. Once complete, run the viya4-deployment tool and it will see and use this setup when creating the openldap server.

<sub>Note that then can only be used when first deploying the openldap server. Afterwards, you can either delete and redeploy the openldap server with a new config or add users via ldapadd.</sub>

For Example:

- /deployments is the BASE_DIR
- Cluster named demo-cluster
- Namespace will be named demo-ns
- Add overlay with custom ldap setup

```bash
  /deployments                          <- parent directory
    /demo-cluster                       <- folder per cluster
      /demo-ns                          <- folder per namespace
        /site-config                    <- location for all customizations
          /openldap                     <- folder containing user defined customizations
            /openldap-modify-users.yaml <- openldap overlay
 ```

## Creating and Managing deployment

Create and manage deployments by either: 

- running [Ansible](docs/user/AnsibleUsage.md) directly on your workstation, or
- running [Docker container](docs/user/DockerUsage.md). 
  
### DNS

During the installation, an ingress loadbalancer can be installed for viya and the monitoring and logging stack. The hostname for these services must be registered with your dns provider to resolve to the loadbalancer's endpoint. This can be done by creating a record per unique ingress host. However, when managing multiple viya deployments, this could get cumbersome. In which case, we recommend creating a dns record that points to the ingress controller's endpoint. The endpoint may be an ip address or fqdn depending on the cloud provider. 

- Create an A record or CNAME (depending on cloud provider) that resolves the desired hostname to the loadbalancers' endpoint. 
- Create a wildcard CNAME record that resolves to the record created in the previous step.
  

For example:

First we lookup the ingress controller's loadbalancer endpoint. Here, we will use kubectl but we could have also checked in the cloud providers portal.

```bash
$ kubectl get service -n ingress-nginx

NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.225.39   52.52.52.52      80:30603/TCP,443:32014/TCP   12d
ingress-nginx-controller-admission   ClusterIP      10.0.99.105   <none>           443/TCP                      12d
```

In the above example, the ingress controller's loadbalancer endpoint is 52.52.52.52. So, we would create the following records:

- An A record (ex. example.com) that points to the 52.52.52.52 address
- A wildcard CNAME (ex *.example.com) that points to the example.com


#### SAS/CONNECT

When running the `viya` action with `V4_CFG_CONNECT_ENABLE_LOADBALANCER=true` a separate service loadbalancer will be created to allow external SAS/CONNECT clients to connect to Viya. You will need to register this loadbalancer endpoint with your dns provider such that an desired hostname (ex. connect.example.com) points to the loadbalancer's endpoint


### Troubleshooting

See [troubleshooting](./docs/Troubleshooting.md) page.

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

- [Viya Resource Guide](https://github.com/sassoftware/viya4-resource-guide)
- [SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure](https://github.com/sassoftware/viya4-iac-azure)
- [SAS Viya 4 Infrastructure as Code (IaC) for Amazon Web Services (AWS)](https://github.com/sassoftware/viya4-iac-aws)
- [Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
- [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
