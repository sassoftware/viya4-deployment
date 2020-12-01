# SAS Viya 4 Deployment

## Overview

This project contains Ansible code that creates a baseline in an existing kubernetes environment for use with Viya 4+, generates the manifest for an order, and then can also deploy that order into the kubernetes environment specified.

### Things this tool can do

- Prepare K8s cluster
  - Deploy [ingress-nginx](https://kubernetes.github.io/ingress-nginx)
  - Deploy [nfs-client-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) for PVs
  - Deploy [efs-client-provisioner](https://hub.helm.sh/charts/stable/efs-provisioner) for PVs in aws
  - Deploy [cert-manager](https://github.com/jetstack/cert-manager) if TLS to be configured
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

### Prerequisites

This tool supports running both from ansible installed on your local machine or via a docker container. The Dockerfile for the container can be found [here](Dockerfile)

#### Ansible

- terraform 0.13.4
- ansible 2.9
- unzip
- tar
- kubectl 1.18
- kustomize 3.7
- python 3
- pip 3
- openshift pip module
- dnspython python module
- helm 3
- git

#### Docker

- docker

#### Infrastructure

Prior to running this playbook some infrastructure needs to be in place

- Kubernetes cluster: You can either bring your own K8s cluster or use one of the Viya 4 IAC projects to create a cluster using terraform.
  - [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure)

- Storage: When using nfs based storage (like Azure NetApp or EFS), then the storage needs certain folders setup. There needs to be a PVs folder created under the export path. This is used for PVs. Additionally, a folder needs to be created for each cluster with sub-folders for bin, data, and homes. Below is the required nfs exports folder structure

  ```bash
  <export_dir>        <- nfs export path
    /pvs              <- location for persistent volumes
    /<namespace>      <- folder per namespace
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
      /astores        <- location for astores
  ```

- JumpBox: This tool can manage nfs folders if you provide ssh access to a JumpBox that has the nfs storage mounted to it at /mnt/viya-share. The Viya 4 IAC projects automate the needed NFS/JumpBox setup if desired. If you wish to manage the nfs server yourself, the JumpBox is not required. Below is the JumpBox folder structure

  ```bash
  /mnt/viya-share/    <- mounted nfs export
    /pvs              <- location for persistent volumes
    /<namespace>      <- folder per namespace
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
      /astores        <- location for astores
  ```

### Installation

#### Ansible

```bash
# clone repo
git clone https://github.com/sassoftware/viya4-deployment.git

# move to directory
cd viya4-deployment

# install ansible collections
ansible-galaxy collection install -r requirements.yaml -f
```

#### Docker

```bash 
# clone repo
git clone https://github.com/sassoftware/viya4-deployment.git

# move to directory
cd viya4-deployment

# build container
docker build -t viya4-deployment .
```

## Getting Started

### Configs

The playbook uses ansible vars for configuration. It is recommended to encrypt both this file and the other configs (sitedefault, kubeconfig, and tfstate) using ansible vault.

### Ansible Vars

The ansible vars file is the main configuration file. Create a file named ansible-vars.yaml to customize any input variable value. For starters, you can copy one of the provided example variable definition files in ./examples folder. For more details on the variables declared in [ansible-vars-azure.yaml](examples/ansible-vars-azure.yaml) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

### Sitedefault

This is a normal VIYA sitedefault file. If none is supplied, the example [sitedefault.yaml](examples/sitedefault.yaml) will be used.

### Kubeconfig

Kubernetes access config file. When not integrating with SAS Viya 4 IaC projects, this must be provided

### Terraform state file

When integrating with SAS Viya 4 IaC projects, you can provide the tfstate file to have the kubeconfig and other setting auto-discovered. The [ansible-vars-iac-azure.yaml](examples/ansible-vars-iac-azure.yaml) example file shows the values that need to be set when using the iac integration.

This following information is parsed from the integration:

- Cloud
  - PROVIDER
  - CLUSTER_NAME
  - Cloud NAT IP address
- NFS
  - V4_CFG_NFS_SVR_HOST
  - V4_CFG_NFS_SVR_PATH
- JumpBox
  - JUMP_SVR_HOST
  - JUMP_SVR_USER
  - JUMP_SVR_PRIVATE_KEY (if a random one is generated)
- Postgres (When V4_CFG_POSTGRES_TYPE is set to external)
  - V4_CFG_POSTGRES_ADMIN_LOGIN
  - V4_CFG_POSTGRES_PASSWORD
  - V4_CFG_POSTGRES_FQDN

### Customizations

viya4-deployment fully manages the kustomize.yaml file. Users can make change by adding custom overlays into sub-folders under the site-config folder. If this is the first time you are running the tool and you need customizations, you can create the folder structure below.

```bash
<base_dir>            <- parent directory
  /<cluster>          <- folder per cluster
    /<namespace>      <- folder per namespace
      /site-config    <- location for all customizations
        ...           <- folders containing user defined customizations
```

#### Viya Customizations

Viya customizations are automatically read in from folders under site-config. To do so, first create the folder structure detailed in the [customizations](#customizations) section above. Afterwards you can copy the desired overlays into a sub-folder under site-config. Once complete you can run the viya4-deployment tool and it will detect and add the overlays to the proper section in the kustomize.yaml

<sub> Note that you do not need to modify the kustomize.yaml. The tool will automatically add the custom overlays to the kustomize.yaml file.<sub>

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

If you enable the embedded openldap server, it is likely you would like to change the users/groups that will be created. This can be done like any other customizations. First create the folder structure detailed in the [customizations](#customizations) section above. Afterwards copy the examples/openldap folder into the site-config folder. Inside the openldap folder is openldap-modify-users.yaml file. Modify it to match your desired setup. Once complete you can run the viya4-deployment tool and it will see and use this setup when creating the openldap server.

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

### Running

All configs needed by ansible are also needed to be mounted into the docker container. In general any file/folder path set via an ansible flag are equivalent to the file/folder being mounted to the docker container at /config/lower_case_variable_name.

Examples:

- The ansible flag `-e KUBECONFIG` is equivalent to `-v <path_to_file>:/config/kubeconfig` when running the docker container
- The ansible flag `-e JUMP_SVR_PRIVATE_KEY` is equivalent to `-v <path_to_file>:/config/jump_svr_private_key` when running the docker container

Below are the only exceptions:

| Ansible Flag | Docker Mount Path | Description | Required |
| :--- | :--- | :--- | ---: |
| -e BASE_DIR | /data | local folder in which all the generated files can be stored. If you do not wish to save the files, this can be omitted | false |
| --vault-password-file | /config/vault_password_file | Full path to file containing the vault password | false |

#### Ansible

In the example command line below, replace each of the <> values, such as "<path_to_kubeconfig_file>", with the appropriate value.

```bash
ansible-playbook \
  -e BASE_DIR=<path_to_store_files> \
  -e KUBECONFIG=<path_to_kubeconfig_file> \
  -e CONFIG=<path_to_ansible_vars_file> \
  -e TFSTATE=<path_to_tfstate_file> \
  -e JUMP_SVR_PRIVATE_KEY=<path_ssh_private_key> \
  playbooks/playbook.yaml \
  --tags "<desired_tasks>,<desired_action>"
```

#### Docker

In the example command line below, replace each of the <> values, such as "<path_to_kubeconfig_file>", with the appropriate value.

```bash
docker run \
  -v <path_to_store_files>:/data \
  -v <path_to_kubeconfig_file>:/config/kubeconfig \
  -v <path_to_ansible_vars_file>:/config/config \
  -v <path_to_tfstate_file>:/config/tfstate \
  -v <path_ssh_private_key>:/config/jump_svr_private_key \
  viya4-deployment --tags "<desired_tasks>,<desired_action>"
```

#### Actions

Actions are used to determine whether in install or uninstall software. One must be set when running the playbook

| Name | Description |
| :--- | ---: |
| Install | Installs the stack required for the specified tasks |
| Uninstall | Uninstalls the stack required for the specified tasks |

#### Tasks

Any number of tasks can be ran at the same time. This means you could run an action against a single task or all the task.

| Name | Description |
| :--- | :--- |
| baseline | Installs needed cluster level tooling needed for all viya deployments. These may include, cert-manager, ingress-nginx, nfs-client-provisioners and more |
| viya | Deploys viya |
| cluster-logging | Installs cluster-wide logging using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| cluster-monitoring | Installs cluster-wide monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| viya-monitoring | Installs viya namespace level monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |

### Post Install

When running the baseline action an ingress will be created. You will need to register this ingress ip with your dns provider such that

- An A record (ex. example.com) points to the <ingress_ip>
- A wildcard (ex *.example.com) points to the <ingress_ip>

When running the viya action with V4_CFG_CONNECT_ENABLE_LOADBALANCER _true_ a load balancer will be created to allow external SAS/CONNECT clients to connect to Viya.
You will need to register this load balancer ip with your dns provider such that
an A record (ex. connect.example.com) points to the <connect_load_balancer_ip>

### Examples

- I have a new cluster, deployed using [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure) project, and want to install everything using docker

  ```bash
  docker run \
    -v $HOME:/data \
    -v $HOME/ansible-vars.yaml:/config/config \
    -v $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install"
  ```

- I have a new cluster, deployed using [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure) project, and want to install everything using ansible

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e TFSTATE=$HOME/viya4-iac-azure/terraform.tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,install"
  ```

- I have a custom built cluster and want to baseline and deploy viya only using ansible

  ```bash
  ansible-playbook \
    -e BASE_DIR=$HOME \
    -e KUBECONFIG=$HOME/.kube/config \
    -e CONFIG=$HOME/ansible-vars.yaml \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
  ```

- I have an existing cluster with viya installed and want to install another viya instance in a different namespace with monitoring, using docker

  ```bash
  docker run \
    -v $HOME:/data \
    -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/defaults.yaml:/config/config \
    -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.ssh:/config/jump_svr_private_key \
    -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.kube:/config/kubeconfig \
    viya4-deployment --tags "viya,viya-monitoring,install"
  ```

- I have a cluster with everything installed and want to uninstall everything using docker

  ```bash
  docker run \
    -v $HOME:/data \
    -v $HOME/ansible-vars.yaml:/config/config \
    -v $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
    viya4-deployment --tags "baseline,viya,cluster-logging,cluster-monitoring,viya-monitoring,uninstall"
  ```

### Troubleshooting

Debug mode can be enabled by adding "-vvv" to the end of the docker or ansible commands

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

- [Viya Resource Guide](https://github.com/sassoftware/viya4-resource-guide)
- [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure)
- [Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
- [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
