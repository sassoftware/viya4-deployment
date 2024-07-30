# Dependency Versions

If your environment requires validated support for a specific version or range of versions, please open a [Issue](https://github.com/sassoftware/viya4-deployment/issues)

The following list details our dependencies and versions (~ indicates multiple possible sources):

| SOURCE         | NAME             | VERSION     |
|----------------|------------------|-------------|
| ~              | python           | >=3.10      |
| ~              | pip              | 3.x         |
| ~              | unzip            | any         |
| ~              | tar              | any         |
| ~              | docker           | >=25.0.3    |
| ~              | git              | any         |
| ~              | rsync            | any         |
| ~              | kubectl          | 1.28 - 1.30 |
| ~              | Helm             | 3.14.2      |
| pip3           | ansible          | 9.2.0       |
| pip3           | openshift        | 0.13.2      |
| pip3           | kubernetes       | 27.2.0      |
| pip3           | dnspython        | 2.6.1       |
| pip3           | docker           | 7.1.0       |
| pip3           | urllib3          | 1.26.18     |
| ansible-galaxy | community.docker | 3.10.3      |
| ansible-galaxy | ansible.utils    | 3.1.0       |
| ansible-galaxy | kubernetes.core  | 3.0.0       |

If you are using a provider based kubeconfig file created by viya4-iac-gcp:4.5.0 or newer, install these dependencies:
| SOURCE         | NAME                    | VERSION     |
|----------------|-------------------------|-------------|
| ~              | gcloud                  | 472.0.0     |
| ~              | gcloud-gke-auth-plugin  | >= 0.5.2    |

Required project dependencies are generally pinned to known working or stable versions to ensure users have a smooth initial experience. In some cases it may be required to change the default version of a dependency. In such cases users are welcome to experiment with alternate versions, however compatibility may not be guaranteed.

# Docker

If deploying via the [Dockerfile](../../Dockerfile) overriding a dependency version can be accomplished by supplying one or more docker build arguments:

| ARG             | NOTE                                   |
|-----------------|----------------------------------------|
| kubectl_version | the version of kubectl to use          |
| aws_cli_version | the version of AWS CLI to use          |
| gcp_cli_version | the version of Google cloud SDK to use |
| helm_version    | the version helm to use                |

As described in the [Docker Installation](./DockerUsage.md) section add additional build arguments to your docker build command:

```bash
# Override kubectl version
docker build \
	--build-arg kubectl_version=1.29.7 \
	-t viya4-deployment .
```

# Ansible

If deploying via the [Ansible Commands](./AnsibleUsage.md) you can modify the dependency requirements files for python and ansible respectively:

| FILE              | FOR                             |
|-------------------|---------------------------------|
| requirements.txt  | dependencies for python         |
| requirements.yaml | dependencies for ansible-galaxy |
