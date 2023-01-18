# Air Gap Installation

> This is still a work in progress, as baseline installation still requires an internet access, because it downloads charts from bitnami.

Installation without (full) internet access requires additionnal step, that are described below.

The main points are:
- download order from internet
- download sas repos corresponding to the order
- push all sas images to a private registry
- clone viya4-deployment github to build the docker image
- start a private web server to serve the order
- install baseline
- install viya

## Prereqs

- Docker [installed on your workstation](Dependencies.md#docker).

## Preparation

### Download Order

Installation requires specific files to download from SAS internet web site, looking like this:
- certificates: `SASViyaV4_XXXXXX_certs.zip`
- deployment assets: `SASViyaV4_XXXXXX_3_stable_2022.12_20230113.1673622017934_deploymentAssets_2023-01-13T154226.tgz`
- license: `SASViyaV4_XXXXXX_3_stable_2022.12_license_2023-01-09T112933.jwt`

First, fill out the required order information in `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values).:
- `V4_CFG_SAS_API_KEY`
- `V4_CFG_SAS_API_SECRET`
- `V4_CFG_ORDER_NUMBER`
- `V4_CFG_CADENCE_NAME`
- `V4_CFG_CADENCE_VERSION`

Next, download `viya4-orders-cli` from `https://github.com/sassoftware/viya4-orders-cli` releases:

```bash
wget https://github.com/sassoftware/viya4-orders-cli/releases/download/1.5.0/viya4-orders-cli_linux_amd64
```

Last, download fies from SAS internet web site to the `./config` folder:

```bash
cd config

# read order variables
cat ansible-vars.yaml | yq '["key",.V4_CFG_SAS_API_KEY],["secret",.V4_CFG_SAS_API_SECRET],["order",.V4_CFG_ORDER_NUMBER],["name",.V4_CFG_CADENCE_NAME],["version",.V4_CFG_CADENCE_VERSION]' -rc | tr -d '[]"' | tr ',' '=' > order.env
source ./order.env

# prepare client credentials key and secret
export CLIENTCREDENTIALSID=$( echo -n "$key" | base64 )
export CLIENTCREDENTIALSSECRET=$( echo -n "$secret" | base64 )

# perform download
../viya4-orders-cli_linux_amd64 certificates $order -o json > certs.json.tmp && mv certs.json.tmp certs.json
../viya4-orders-cli_linux_amd64 deploymentAssets $order $name $version -o json > deploymentAssets.json.tmp && mv deploymentAssets.json.tmp deploymentAssets.json
../viya4-orders-cli_linux_amd64 license $order $name $version -o json > license.json.tmp && mv license.json.tmp license.json
```

Keep the json files near the downloaded files as they contain the full name of the downloaded files.

### Download SAS Repos

To download files into `./download` folder, using order from `./config`:

```bash
# read order variables
source ./config/order.env
release=$( cat config/deploymentAssets.json | jq .cadenceRelease -r )

# prepare download variables
DEPLOYMENT_DATA=$( cat certs.json | jq .assetLocation -r )
DEPLOYMENT_DATA=$PWD/config/${DEPLOYMENT_DATA##*/}
PARALLEL_DOWNLOAD=10
CADENCE=$name-$version
RELEASE=$release

# download SAS mirror manager
cd download
[ -x mirrormgr ] || {
    proxy wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
    tar -xvf mirrormgr-linux.tgz 
}

# download SAS repos
./mirrormgr mirror registry --path ../sas_repos --cadence $CADENCE --release $RELEASE --deployment-data $DEPLOYMENT_DATA --workers $PARALLEL_DOWNLOAD
```

This will download several dozen gigabytes and can take several hours to complete.

### Push all images to a private registry

As explained in SAS documentation, sas mirror mananager can also push all images to a private registry:

```bash
# read order variables
source ./config/order.env

# prepare download variables
DEPLOYMENT_DATA=$( cat config/certs.json | jq .assetLocation -r )
DEPLOYMENT_DATA=$PWD/config/${DEPLOYMENT_DATA##*/}
REGISTRY=registry.localdomain:5000

cd download
./mirrormgr mirror registry --path ../sas_repos --deployment-data $DEPLOYMENT_DATA --destination $REGISTRY --push-only
```

Modify above script according to your needs, like registry username and password, ...

### Docker image

Run the following command to create the `viya4-deployment` Docker image using the provided [Dockerfile](../../Dockerfile)

```bash
docker build -t viya4-deployment .
```
The Docker image `viya4-deployment` will contain ansible, cloud provider cli's and 'kubectl' executables. The Docker entrypoint for the image is `ansible-playbook` that will be run with sub-commands in the subsequent steps.

> Build does not work if done behind a proxy, as one of its component (azure?) installation script does not handle proxy settings.
> The solution is to remove all AWS, Azure and GCP references to the Dockerfile before building the image.

> If it is required to add CA Certificates to the image:
> - create a new extra folder `/usr/local/share/ca-certificates/extra/` 
> - copy all CA certificates in that folder - names MUST end with .crt
> - docker build will automatically load them and create `/etc/ssl/certs/ca-certificates.crt`

## Running

### Serve Order Files

As installation process needs to download the order, start a very simple web server to serve the order on port 80:

```bash
docker run --rm --network host --name repos-sas ${1:--d} \
    -v $PWD/sas_repos:/sas_repos:ro \
    -w /sas_repos \
    python:3-alpine \
    python -m http.server 80
```

### Docker Volume Mounts

All configs needed by ansible are also needed to be mounted into the docker container. In general any file/folder path set via an ansible flag are equivalent to the file/folder being mounted to the docker container at `/config/<lower_case_variable_name>`. 

See [Docker Volume Mapping](DockerVolumeMounts.md) for the full list of docker volume mappings.

Examples:

- The ansible flag `-e KUBECONFIG` is equivalent to `--volume <desire_path>:/config/kubeconfig` when running the docker container
- The ansible flag `-e JUMP_SVR_PRIVATE_KEY` is equivalent to `--volume <desire_path>:/config/jump_svr_private_key` when running the docker container
- The ansible flag `-e V4_CFG_SITEDEFAULT` is equivalent to `--volume <desire_path>:/config/v4_cfg_sitedefault` when running the docker container

Below are the only exceptions:

| Ansible Flag | Docker Mount Path | Description | Required |
| :--- | :--- | :--- | ---: |
| -e BASE_DIR | `/data` | local folder in which all the generated files can be stored. If you do not wish to save the files, this can be omitted | false |
| --vault-password-file | `/config/vault_password_file` | Full path to file containing the Ansible vault password | false |

### Variable Definitions (ansible-vars.yaml) File

Prepare your `ansible-vars.yaml` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running

Declare the Actions and Task to be performed

### Actions

Actions are used to install or uninstall software. One must be set when running the playbook.

| Name | Description |
| :--- | ---: |
| install | Installs the stack required for the specified tasks |
| uninstall | Uninstalls the stack required for the specified tasks |

### Tasks

Any number of tasks can be run at the same time. An action can run against a single task or all tasks.

| Name | Description |
| :--- | :--- |
| baseline | Installs cluster level tooling needed for all viya deployments. These may include, cert-manager, ingress-nginx, nfs-client-provisioners and more. |
| viya | Deploys viya |
| cluster-logging | Installs cluster-wide logging using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| cluster-monitoring | Installs cluster-wide monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |
| viya-monitoring | Installs viya namespace level monitoring using the [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) project. |

### Example

```bash
# read order variables
certs=$( cat config/certs.json | jq .assetLocation -r )
deploymentAssets=$( cat config/deploymentAssets.json | jq .assetLocation -r )
license=$( cat config/license.json | jq .assetLocation -r )
certs=${certs##*/}
deploymentAssets=${deploymentAssets##*/}
license=${license##*/}

# read other variables
cluster_name=$( cat config/ansible-vars.yaml | yq .CLUSTER_NAME -re )
namespace=$( cat config/ansible-vars.yaml | yq .NAMESPACE -re )

# copy site-config to data folder
rsync -a config/site-config/ data/$cluster_name/$namespace/site-config/

# perform installation
docker run --rm -it --network=host --name sas-deployment --group-add root --user 0:0 \
    -v $PWD/config/$certs:/config/v4_cfg_certs:ro \
    -v $PWD/config/$deploymentAssets:/config/v4_cfg_deployment_assets:ro \
    -v $PWD/config/$license:/config/v4_cfg_license:ro \
    -v $PWD/config/ansible-vars.yaml:/config/config:ro \
    -v $PWD/data:/data \
    -v $PWD/viya4-deployment:/viya4-deployment.new:ro \
    -v ~/.kube/config:/config/kubeconfig:ro \
    -e SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    viya4-deployment \
    --tags baseline,viya,install
```
