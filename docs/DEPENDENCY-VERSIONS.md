# Dependency Versions

If your environment requires validated support for a specific version or range of versions, please open a [Issue](https://github.com/sassoftware/viya4-deployment/issues)

The following list details our dependencies and versions (~ indicates multiple possible sources):

SOURCE | NAME | VERSION
--- | --- | ---
~ | python | 3.x
~ | pip | 3.x
~ | unzip | any
~ | tar | any
~ | docker | any
~ | git | any
~ | terraform | 0.13.6
~ | kustomize | 3.7.0
~ | kubectl | 1.18.8
~ | AWS IAM Authenticator | 1.18.9/2020-11-02
~ | Helm | 3
pip3 | ansible | 2.10.0
pip3 | openshift | 0.11.2
pip3 | kubernetes | 11.0.0
pip3 | dnspython | 2.1.0
ansible-galaxy | community.kubernetes | 1.2.0
ansible-galaxy | ansible.posix | 1.1.1

Required project dependencies are generally pinned to known working or stable versions to ensure users have a smooth first-start experience. In some cases it may be required to change the default version of a dependency. In such cases users are welcome to experiment with alternate versions, however compatability may not be guarrenteed.

# Docker

If deploying via the [Dockerfile](../Dockerfile) overriding a dependency version can be accomplished by supplying one or more docker build arguments:

ARG | NOTE
--- | ---
terraform_version | the version of terraform to use
kustomize_version | the version of kustomize to use
kubectl_version | the version of kubectl to use
aws_iam_authenticator_version | the version of aws iam authenticator to use
pip_ansible_version | the version of ansible to use from pip
pip_openshift_version | the version of openshift to install from pip
pip_kubernetes_version | the version of kubernetes to install from pip
pip_dnspython | the version of dynspython to install from pip
ansible_galaxy_community_kubernetes_version | the version of community.kubernetes to install from ansible-galaxy
ansible_galaxy_ansible_posix_version | the version of ansible.posix to install from ansible-galaxy

As described in the [Docker Installation](../README.md#docker-1) section add additional build arguments to your docker build command:

```bash
docker build \
	--build-arg terraform_version=0.13.0 \
	--build-arg pip_openshift_version=0.12.0 \
	-t viya4-deployment .
```

# Ansible

If deploying via the [Ansible Commands](../README.md#ansible-1) you can modify the dependency requirements files for python and ansible respectivly:

FILE | FOR
--- | ---
requirements.txt | dependencies for python
requirements.yaml | dependencies for ansible-galaxy