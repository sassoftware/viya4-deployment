# Dependency Versions

If your environment requires validated support for a specific version or range of versions, please open a [Issue](https://github.com/sassoftware/viya4-deployment/issues)

The following list details our dependencies and versions (~ indicates multiple possible sources):

| SOURCE | NAME | VERSION |
| --- | --- | --- |
| ~ | python | 3.x |
| ~ | pip | 3.x |
| ~ | unzip | any |
| ~ | tar | any |
| ~ | docker | any |
| ~ | git | any |
| ~ | kustomize | 3.7.0 |
| ~ | kubectl | 1.21 - 1.23 |
| ~ | Helm | 3 |
| pip3 | ansible | 2.10.7 |
| pip3 | openshift | 0.12.0 |
| pip3 | kubernetes | 12.0.1 |
| pip3 | dnspython | 2.1.0 |
| pip3 | docker | 5.0.3 |
| ansible-galaxy | community.kubernetes | 1.2.1 |
| ansible-galaxy | community.docker | 2.7.0 |
| ansible-galaxy | ansible.utils | 2.3.0 |

Required project dependencies are generally pinned to known working or stable versions to ensure users have a smooth initial experience. In some cases it may be required to change the default version of a dependency. In such cases users are welcome to experiment with alternate versions, however compatibility may not be guaranteed.

# Docker

If deploying via the [Dockerfile](../../Dockerfile) overriding a dependency version can be accomplished by supplying one or more docker build arguments:

| ARG | NOTE |
| --- | --- |
| kustomize_version | the version of kustomize to use |
| kubectl_version | the version of kubectl to use |
| aws_cli_version | the version of AWS CLI to use |
| gcp_cli_version | the version of Google cloud SDK to use |
| helm_version | the version helm to use |

As described in the [Docker Installation](./DockerUsage.md) section add additional build arguments to your docker build command:

```bash
docker build \
	--build-arg kubectl_version=1.23.9 \
	-t viya4-deployment .
```

# Ansible

If deploying via the [Ansible Commands](./AnsibleUsage.md) you can modify the dependency requirements files for python and ansible respectively:

| FILE | FOR |
| --- | --- |
| requirements.txt | dependencies for python |
| requirements.yaml | dependencies for ansible-galaxy |
