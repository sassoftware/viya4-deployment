# Kubernetes Configuration File Types

## Overview

### Notes - viya4-deployment:6.6.0

The release of kubectl v1.26 is dropping support for built-in provider-specific code in their project for authentication and instead opting for a plugin-based strategy. To quote this [Google blog post](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke):

>To ensure the separation between the open source version of Kubernetes and those versions that are customized by services providers like Google, the open source community is requiring that all provider-specific code that currently exists in the OSS code base be removed starting with v1.26.

### Usage with viya4-iac-gcp:4.5.0

Two types of Kubernetes configuration files can be created with the viay4-iac-gcp project:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

For GKE clusters, the provider based kubernetes configuration file format will change to support the use of the `gke-gcloud-auth-plugin`. The `gke-gcloud-auth-plugin` binary is required to access any GKE clusters when using kubectl 1.26+ with a "provider based" kubernetes configuration file. For use with the viya4-deployemnt project, the "service account and cluster role binding" kubernetes configuration file variant remains the same and does not require either `gcloud` or the `gke-gcloud-auth-plugin` binary to communicate with the cluster.

The viya4-deployment Dockerfile includes steps to ensure that the plugin is installed and enabled. If you opt not to use this project via a Docker container produced with the included Dockerfile, you will need to take steps to install both `gcloud` and `gke-gcloud-auth-plugin` on your machine. Google has provided step-by-step instructions in a blog post to aid users with this transition. See [Google's Authentication Blog post](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke).

See the [viya4-iac-gcp Kubeconfig document](https://github.com/sassoftware/viya4-iac-gcp/blob/main/docs/user/Kubeconfig.md) for more details on creating both types of GKE Kubernetes Configuration files.

### Examples

- I have opted to use this project via a Docker container produced with the provided Dockerfile. I have a provider based Kubernetes Configuration File and I want to baseline and deploy Viya only.

  ```bash
  docker run --rm --group-add root --user "$(id -u):$(id -g)" --volume "$HOME"/deployments:/data \
  --volume $HOME/deployments/dev-cluster/dev-namespace/ansible-vars-iac-gcp.yaml:/config/config \
  --volume $HOME/terraform.tfstate:/config/tfstate \
  --volume $HOME/.ssh/id_rsa:/config/jump_svr_private_key \
  --volume $HOME/public/davhou-696f-gke-kubeconfig-client.conf:/config/kubeconfig \
  --volume $HOME/credentials/.gcp-service-account.json:/config/v4_cfg_cloud_service_account_auth \
  viya4-deployment --tags "baseline,viya,install" -v -e V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME=proj-terraform@project.iam.gserviceaccount.com
  ```

- I have opted not to use this project via a Docker container produced with the provided Dockerfile. I have followed the steps linked above to install both `gcloud` and the `gke-gcloud-auth-plugin`. I have a provider based Kubernetes Configuration File and I want to baseline and deploy Viya only.

  ```bash
  ansible-playbook \
    -e V4M_VERSION=stable -e BASE_DIR=$HOME/deployments \
    -e KUBECONFIG=$HOME/deployments/dev-cluster/dev-namespace/prefix-gke-kubeconfig-client.conf \
    -e CONFIG=$HOME/deployments/dev-cluster/dev-namespace/ansible-vars-iac-gcp.yaml \
    -e TFSTATE=$HOME/deployments/dev-cluster/dev-namespace/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=$HOME/.ssh/id_rsa \
    -e V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME=proj-terraform@project.iam.gserviceaccount.com \
    -e V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH=$HOME/creds/.gcp-service-account.json \
    playbooks/playbook.yaml --tags "baseline,viya,install" -v
```
