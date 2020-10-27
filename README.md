# SAS Viya 4 Deployment

## Overview

This project contains Ansible code that creates a baseline in an existing kubernetes environment for use with Viya 4+, generates the manifest for an order, and then can also deploy that order into the kubernetes environment specified.

### Things this tool can do

- Prepare K8s cluster
  - Deploy [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
  - Deploy [istio](https://istio.io/)
  - Deploy [nfs-client-provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) for PVs
  - Deploy [efs-client-provisioner](https://hub.helm.sh/charts/stable/efs-provisioner) for PVs in aws
  - Deploy [cert-manager](https://github.com/jetstack/cert-manager) if TLS to be configured
  - Manage storage classes for RWO and RWX storage
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

- terraform 0.13
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
  - [Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws)
  - [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure)
  - [Viya 4 IaC for GCP](https://github.com/sassoftware/viya4-iac-gcp)

- Storage: When using nfs based storage (like Azure NetApp or EFS), then the storage needs certain folders setup. There needs to be a PVs folder created under the export path. This is used for PVs. Additionally, a folder needs to be created for each cluster with sub-folders for bin, data, and homes. Below is the required nfs exports folder structure

  ```bash
  <export_dir>        <- nfs export path
    /pvs              <- location for persistent volumes
    /<cluster_name>   <- folder per k8s cluster
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
  ```

- Jump Box: This tool can manage nfs folders if you provide ssh access to a JumpBox that has the nfs storage mounted to it at /mnt/viya-share. The Viya 4 IAC projects automate the needed NFS/Jumpbox setup if desired. If you wish to manage the nfs server yourself, the Jumpbox is not required. Below is the Jumpbox folder structure

  ```bash
  /mnt/viya-share/    <- mounted nfs export
    /pvs              <- location for persistent volumes
    /<cluster_name>   <- folder per k8s cluster
      /bin            <- location for open source directories
      /data           <- location for SAS and CAS Data
      /homes          <- location for user home directories to be mounted
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

[Definitions](docs/CONFIG-VARS.md)

[Azure Sample](examples/ansible-vars-azure.yaml)

### Sitedefault

Normal VIYA sitedefault file. When not specified, the following will be used:

[Sample](examples/sitedefault.yaml)

### Kubeconfig

Kubernetes access config file. When not integrating with SAS Viya 4 IaC projects, this must be provided

### Terraform state file

When integrating with SAS Viya 4 IaC projects, you can provide the tfstate file to have the kubeconfig and other setting auto-discovered. This information includes

- Cloud
  - PROVIDER
  - CLUSTER_NAME
  - Cloud NAT IP address
- NFS
  - V4_CFG_NFS_SVR_HOST
  - V4_CFG_NFS_SVR_PATH
- Jumpbox
  - JUMP_SVR_HOST
  - JUMP_SVR_USER
  - JUMP_SVR_PRIVATE_KEY (if a random one is generated)
- Postgres (When V4_CFG_POSTGRES_TYPE is set to external)
  - V4_CFG_POSTGRES_ADMIN_LOGIN
  - V4_CFG_POSTGRES_PASSWORD
  - V4_CFG_POSTGRES_FQDN


### Running

All configs needed by ansible are also needed to be mounted into the docker container. The chart below show the mappings between the ansible flag and docker mount path.

| Ansible Flag | Docker Mount Path | Description | Required |
| :--- | :--- | :--- | ---: |
| BASE_DIR | /data | local folder in which all the generated files can be stored. If you do not wish to save the files, this can be omitted | false |
| KUBE | /config/kube | Full path to the kubeconfig file. When integrating with the SAS Viya 4 IaC projects, this can be omitted | false |
| CONFIG | /config/config | Full path to the ansible vars | true |
| TFSTATE | /config/tfstate | Full path to the tfstate file. Only required when integrating with the SAS Viya 4 IaC projects | false |
| JUMP_SVR_PRIVATE_KEY | /config/jump_svr_private_key | Full path to the ssh_private_key that has access to the jumpbox | true |

#### Ansible

In the example command line below, replace each of the <> values, such as "<path_to_kubeconfig_file>", with the appropriate value.

```bash
ansible-playbook \
  -e BASE_DIR=<path_to_store_files> \
  -e KUBE=<path_to_kubeconfig_file> \
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
  -v <path_to_kubeconfig_file>:/config/kube \
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
| vdm | Deploys viya |
| cluster-logging | Installs cluster-wide logging using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| cluster-monitoring | Installs cluster-wide monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| viya-monitoring | Installs viya namespace level monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |

### Post Install

When running the baseline action an ingress will be created. You will need to register this ingress ip with your dns provider such that

- An A record (ex. example.com) points to the <ingress_ip>
- A wildcard (ex *.example.com) points to the <ingress_ip>

### Examples

- I have a new cluster, deployed using [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure) project, and want to install everything using docker

  ```bash
  docker run \
  -v $HOME:/data \
  -v $HOME/ansible-vars.yaml:/config/config \
  -v $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
  viya4-deployment --tags "baseline,vdm,cluster-logging,cluster-monitoring,viya-monitoring,install"
  ```

- I have a custom built cluster and want to baseline and deploy viya only using ansible

  ```bash
  ansible-playbook \
    -e KUBE=$HOME/.kube/config \
    -e CONFIG=$HOME/ansible-vars.yaml\
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa\
    playbooks/playbook.yaml --tags "baseline,vdm,install"
  ```

- I have an existing cluster with viya installed and want to install another viya instance in a different namespace with monitoring, using docker

  ```bash
  docker run \
  -v $HOME:/data \
  -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/defaults.yaml:/config/config \
  -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.ssh:/config/jump_svr_private_key \
  -v $HOME/viya-deployments/deployments/azure/my_az_account/demo-aks/namespace2/site-config/.kube:/config/kube \
  viya4-deployment --tags "vdm,viya-monitoring,install"
  ```

- I have a cluster with everything installed and want to uninstall everything using docker

  ```bash
  docker run \
  -v $HOME:/data \
  -v $HOME/ansible-vars.yaml:/config/config \
  -v $HOME/viya4-iac-azure/terraform.tfstate:/config/tfstate \
  viya4-deployment --tags "baseline,vdm,cluster-logging,cluster-monitoring,viya-monitoring,uninstall"
  ```

### Troubleshooting

Debug mode can be enabled by adding "-vvv" to the end of the docker or ansible commands

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

- [Viya Resource Guide](https://github.com/sassoftware/viya4-resource-guide)
- [Viya 4 IaC for AWS](https://github.com/sassoftware/viya4-iac-aws)
- [Viya 4 IaC for Azure](https://github.com/sassoftware/viya4-iac-azure)
- [Viya 4 IaC for GCP](https://github.com/sassoftware/viya4-iac-gcp)
- [Viya Monitoring for Kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes)
- [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli)
