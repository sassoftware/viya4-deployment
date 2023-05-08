# Kubernetes Configuration File Types

## Overview

### Notes - viya4-deployment:6.6.0

The release of kubectl v1.26 is dropping support for built-in provider-specific code in their project for authentication and instead opting for a plugin-based strategy. A quote from the [Google blog](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke) provides an explanation for this change:

>To ensure the separation between the open source version of Kubernetes and those versions that are customized by services providers like Google, the open source community is requiring that all provider-specific code that currently exists in the OSS code base be removed starting with v1.26.

### Usage with provider based kubeconfig files from viya4-iac-gcp:4.5.0

Two types of Kubernetes configuration files can be created with the [viya4-iac-gcp](https://github.com/sassoftware/viya4-iac-gcp) project:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

Starting with viya4-iac-gcp:4.5.0, the provider based kubernetes configuration file format will change to support use of the `gke-gcloud-auth-plugin`. The `gke-gcloud-auth-plugin` binary is required to access any GKE clusters when using kubectl 1.26+ with a "provider based" kubernetes configuration file. When used with the viya4-deployment project, the "service account and cluster role binding" kubernetes configuration file variant remains the same and does not require either `gcloud` or the `gke-gcloud-auth-plugin` binary to communicate with the cluster.

The viya4-deployment Dockerfile includes steps to ensure that the `gke-gcloud-auth-plugin` is installed and enabled for use with provider based kubeconfig files. If you opt to [use the Ansible CLI](./AnsibleUsage.md) with this project instead of a Docker container produced with the included Dockerfile, and you are using a provider based kubeconfig file, you will need to take steps to install both `gcloud` and the `gke-gcloud-auth-plugin` on your machine. Google has provided step-by-step instructions in a blog post to aid users with this transition. See [Google's Authentication Blog post](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke).

See the [viya4-iac-gcp Kubeconfig document](https://github.com/sassoftware/viya4-iac-gcp/blob/main/docs/user/Kubeconfig.md) for more details on creating both types of GKE Kubernetes Configuration files.

### Examples

Using the viya4-deployment project with a viya4-iac-gcp "provider based" kubeconfig file requires providing values for the V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME and a V4_CLOUD_SERVICE_ACCOUNT_AUTH file. Refer to the section below for examples of how to express those two values with either the docker container or ansible CLI usage patterns.

- I have opted to use this project via a Docker container produced with the provided Dockerfile. I have a provider based Kubernetes configuration file and I want to baseline and deploy Viya only.

  ```bash
  docker run --rm --group-add root --user "$(id -u):$(id -g)" --volume "$HOME"/deployments:/data \
  --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars-iac-gcp.yaml:/config/config \
  --volume $HOME/terraform.tfstate:/config/tfstate \
  --volume $HOME/.ssh/id_rsa:/config/jump_svr_private_key \
  --volume $HOME/public/prefix-gke-kubeconfig.conf:/config/kubeconfig \
  --volume $HOME/credentials/.gcp-service-account.json:/config/v4_cfg_cloud_service_account_auth \
  viya4-deployment --tags "baseline,viya,install" -v -e V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME=proj-terraform@project.iam.gserviceaccount.com
  ```

- I have opted to use this project with the ansible CLI and have followed the linked steps above to install both `gcloud` and the `gke-gcloud-auth-plugin`. I have a provider based Kubernetes configuration file and I want to baseline and deploy Viya only.

  ```bash
  ansible-playbook \
    -e V4M_VERSION=stable -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/dev-cluster/dev-namespace/prefix-gke-kubeconfig.conf \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars-iac-gcp.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/dev-namespace/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    -e V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME=proj-terraform@project.iam.gserviceaccount.com \
    -e V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH=$HOME/creds/.gcp-service-account.json \
    playbooks/playbook.yaml --tags "baseline,viya,install" -v
```
