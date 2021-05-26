# List of valid configuration variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

- [List of valid configuration variables](#list-of-valid-configuration-variables)
  - [BASE](#base)
  - [3rd Party tools](#3rd-party-tools)
  - [Cloud](#cloud)
    - [Authentication](#authentication)
  - [Jump Server](#jump-server)
  - [Storage](#storage)
    - [RWX Filestore](#rwx-filestore)
    - [Azure](#azure)
    - [AWS](#aws)
    - [GCP](#gcp)
  - [Order](#order)
  - [SAS API Access](#sas-api-access)
  - [Container Registry Access](#container-registry-access)
  - [Ingress](#ingress)
  - [Monitoring and Logging](#monitoring-and-logging)
    - [Monitoring](#monitoring)
    - [Logging](#logging)
  - [TLS](#tls)
    - [Cert-manager](#cert-manager)
  - [Postgres](#postgres)
    - [External Postgres](#external-postgres)
  - [CAS](#cas)
  - [CONNECT](#connect)
  - [Miscellaneous](#miscellaneous)

## BASE

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy or stop at generating kustomize and manifest | bool | true | false | | viya |
| LOADBALANCER_SOURCE_RANGES | IPs to allow to ingress | [string] | | true | When deploying in the cloud, be sure to add the cloud nat ip | baseline, viya |
| BASE_DIR | Path to store persistent files | string | $HOME | false | | all |
| KUBECONFIG | Path to kubeconfig file | string | | true | | viya |
| V4_CFG_SITEDEFAULT | Path to sitedefault file | string | | false | When not set [sitedefault](examples/sitedefault.yaml) is used | viya |
| V4_CFG_SSSD | Path to sssd file | string | | false | | viya |

## 3rd Party tools

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CERT_MANAGER_NAME | cert-manager helm release name | string | cert-manager | false | | baseline |
| CERT_MANAGER_NAMESPACE | cert-manager helm install namespace | string | cert-manager | false | | baseline |
| CERT_MANAGER_CHART_VERSION | cert-manager helm chart version | string | 1.3.0 | false | | baseline |
| CERT_MANAGER_CHART_URL | cert-manager helm chart url | string | https://charts.jetstack.io/ | false | | baseline |
| CERT_MANAGER_CONFIG | cert-manager helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| | | | | | | |
| INGRESS_NGINX_NAME | ingress-nginx helm release name | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_NAMESPACE | ingress-nginx helm install namespace | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_VERSION | ingress-nginx helm chart version | string | 3.20.1| false | | baseline |
| INGRESS_NGINX_CHART_URL | ingress-nginx helm chart url | string | https://kubernetes.github.io/ingress-nginx | false | | baseline |
| INGRESS_NGINX_CONFIG | ingress-nginx helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| | | | | | | |
| NFS_NAME | nfs-subdir-external-provisioner helm release name | string | nfs-subdir-external-provisioner | false | | baseline |
| NFS_NAMESPACE | nfs-subdir-external-provisioner helm install namespace | string | nfs-client | false | | baseline |
| NFS_CHART_VERSION | nfs-subdir-external-provisioner helm chart version | string | 4.0.8| false | | baseline |
| NFS_CHART_URL | nfs-subdir-external-provisioner helm chart url | string | https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ | false | | baseline |
| NFS_CONFIG | nfs-subdir-external-provisioner helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| | | | | | | |
| METRICS_SERVER_NAME | metrics-server helm release name | string | metrics-server | false | | baseline |
| METRICS_SERVER_CHART_VERSION | metrics-server helm chart version | string | 5.3.5 | false | | baseline |
| METRICS_SERVER_CHART_URL | metrics-server helm chart url | string | https://charts.bitnami.com/bitnami/ | false | | baseline |
| METRICS_SERVER_CONFIG | metrics-server helm values | string | see [here](../roles/baseline/defaults/main.yml) | | baseline |

## Cloud

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, viya |
| CLUSTER_NAME | Name of the k8s cluster | string | | true | | baseline, viya |
| NAMESPACE | K8s namespace in which to deploy | string | | true | | baseline, viya, viya-monitoring |

### Authentication

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME | Cloud service account | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH | Full path to service account credentials file | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |

## Jump Server
Tool uses the jump server to interact with rwx filestore, that needs to be pre-mounted to JUMP_SVR_RWX_FILESTORE_PATH, when V4_CFG_MANAGE_STORAGE is set true.

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| JUMP_SVR_HOST | ip/fqn to the jump host | string | | true | | baseline, viya |
| JUMP_SVR_USER | ssh user to access the jump host | string | | true | | baseline, viya |
| JUMP_SVR_PRIVATE_KEY | Path to ssh user private key to access the jump host | string |  | true | | baseline, viya |
| JUMP_SVR_RWX_FILESTORE_PATH | Path on jump server to nfs mount | string | /viya-share | false | | viya |

## Storage

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_MANAGE_STORAGE | Should the tool manage the storageclass | bool | true | false | Set to false if you wish to manage the storage class | all |
| V4_CFG_STORAGECLASS | Storageclass name | string | "sas" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting storage class that supports ReadWriteMany | baseline, viya |

### RWX Filestore

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_RWX_FILESTORE_ENDPOINT | NFS ip/host | string | | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_PATH | NFS export path | string | /export | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_ASTORES_PATH | NFS path to astores dir | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/astores | false | | viya |
| V4_CFG_RWX_FILESTORE_BIN_PATH | NFS path to bin dir | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/bin | false | | viya |
| V4_CFG_RWX_FILESTORE_DATA_PATH | NFS path to data dir | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/data | false | | viya |
| V4_CFG_RWX_FILESTORE_HOMES_PATH | NFS path to homes dir | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/homes | false | | viya |

### Azure

When setting V4_CFG_MANAGE_STORAGE to true, A new storage classes will be created: sas (Azure Netapp or NFS)

### AWS

When setting V4_CFG_MANAGE_STORAGE to true, the efs-provisioner will be deployed. A new storage classes will be created: sas (EFS or NFS)

### GCP

When setting V4_CFG_MANAGE_STORAGE to true, A new storage classes will be created: sas (Google Filestore or NFS)

## Order

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ORDER_NUMBER | SAS order number | string | | true | | viya |
| V4_CFG_CADENCE_NAME | Cadence name | string | lts | false | [stable,lts] | viya |
| V4_CFG_CADENCE_VERSION | Cadence version | string | 2020.1 | true | | viya |
| V4_CFG_DEPLOYMENT_ASSETS | Path to pre-downloaded deployment assets | string | | false | Leave blank to download deployment assets | viya |
| V4_CFG_LICENSE | Path to pre-downloaded license file | string | | false| Leave blank to download license file | viya |

## SAS API Access

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_API_KEY | SAS API Key| string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |
| V4_CFG_SAS_API_SECRET | SAS API Secret | string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |

## Container Registry Access

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | false | By default, credentials are already included in the downloaded deploymentAssets | viya |
| V4_CFG_CR_PASSWORD | Container registry password | string | | false | By default, credentials are already included in the downloaded deploymentAssets | viya |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | | viya |

## Ingress

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | Which ingress to deploy | string | | true | [ingress] | baseline, viya |
| V4_CFG_INGRESS_FQDN | FQDN to for viya installation | string | | true | | viya |

## Monitoring and Logging

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_VERSION | Branch or tag of [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) | string | stable | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_BASE_DOMAIN | Base domain in which subdomains for elasticsearch, kibana, grafana, prometheus and alertmanager will be created | string | | false | This or the per service fqdn's must be set | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_CERT | Path to tls certificate to use for all monitoring/logging services | string | | false | Alternately you can set the per service cert | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_KEY | Path to tls key to use for all monitoring/logging services | string | | false | Alternately you can set the per service cert | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_NODE_PLACEMENT_ENABLE | Enable workload node placement for viya4-monitoring-kubernetes stack | bool | false | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_STORAGECLASS | Storageclass name | string | v4m | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your pre-existing storage class that supports ReadWriteOnce | cluster-logging, cluster-monitoring, viya-monitoring |

### Monitoring

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_PROMETHEUS_FQDN | FQDN to use for prometheus ingress | string | prometheus.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_PROMETHEUS_CERT | Path to tls certificate to use for prometheus ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-monitoring |
| V4M_PROMETHEUS_KEY | Path to tls key to use for prometheus ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-monitoring |
| | | | | | | |
| V4M_GRAFANA_FQDN | FQDN to use for grafana ingress | string | grafana.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_GRAFANA_CERT | Path to tls certificate to use for grafana ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-monitoring |
| V4M_GRAFANA_KEY | Path to tls key to use for grafana ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-monitoring |
| V4M_GRAFANA_PASSWORD | Grafana admin password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-monitoring |
| | | | | | | |
| V4M_ALERTMANAGER_FQDN | FQDN to use for alertmanager ingress | string | alertmanager.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_ALERTMANAGER_CERT | Path to tls certificate to use for alertmanager ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-monitoring |
| V4M_ALERTMANAGER_KEY | Path to tls key to use for alertmanager ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-monitoring |

### Logging

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_KIBANA_FQDN | FQDN to use for kibana ingress | string | kibana.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_KIBANA_CERT | Path to tls certificate to use for kibana ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-logging |
| V4M_KIBANA_KEY | Path to tls key to use for kibana ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-logging |
| V4M_KIBANA_PASSWORD | Kibana admin password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-logging |
| | | | | | | |
| V4M_ELASTICSEARCH_FQDN | FQDN to use for elasticsearch ingress  | string | elasticsearch.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_ELASTICSEARCH_CERT | Path to tls certificate to use for elasticsearch ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-logging |
| V4M_ELASTICSEARCH_KEY | Path to tls key to use for elasticsearch ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-logging |

## TLS

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_TLS_MODE | Which TLS mode to configure | string | front-door | false | Valid values are full-stack, front-door and disabled. When deploying full-stack you must set V4_CFG_TLS_TRUSTED_CA_CERTS to trust external postgres server ca | all |
| V4_CFG_TLS_CERT | Path to ingress certificate file | string | | false | If specified, used instead of cert-manager issued certificates | viya |
| V4_CFG_TLS_KEY | Path to ingress key file | string | | false | Required when V4_CFG_TLS_CERT is specified | viya |
| V4_CFG_TLS_TRUSTED_CA_CERTS | Path to directory containing only PEM encoded trusted CA certificates files | string | | false | Required when V4_CFG_TLS_CERT is specified. Must include all the CAs in the trust chain for V4_CFG_TLS_CERT. Can be used with or without V4_CFG_TLS_CERT to specify any additionally trusted CAs  | viya |

### Cert-manager

When setting V4_CFG_TLS_MODE to a value other than "disabled" and no V4_CFG_TLS_CERT is specified, cert-manager will be used to issue TLS certificates and the following variables can be set to modify cert-manager behavior:

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CM_CERTIFICATE_DURATION | Certificate time to expiry in hours | string | 17531h | false | | viya |
| V4_CFG_CM_CERTIFICATE_ADDITIONAL_SAN_DNS | A list of space separated, additional SAN DNS entries, specific to your ingress architecture, that you want added to certificates issued by the sas-viya-issuer.  For example, the aliases of an external load balancer | string | | false | | viya |
| V4_CFG_CM_CERTIFICATE_ADDITIONAL_SAN_IP | A list of space separated, additional SAN IP addresses, specific to your ingress architecture, that you want added to certificates issued by the sas-viya-issuer.  For example, the IP address of an external load balancer | string | | false | | viya |

## Postgres

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_TYPE | Postgres installation type | string | | true | [internal,external] | viya |

### External Postgres

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_ADMIN_LOGIN | Existing postgres username | string | | true | | viya |
| V4_CFG_POSTGRES_PASSWORD | Existing postgres password | string | | true | | viya |
| V4_CFG_POSTGRES_FQDN | Existing postgres ip/fqdn | string | | true | | viya |
| V4_CFG_POSTGRES_PORT | Existing postgres port | string | 5432 | false | | viya |
| V4_CFG_POSTGRES_DATABASE | Existing postgres database name | string | "SharedServices" | false | | viya |
| V4_CFG_POSTGRES_CONNECTION_NAME | Existing postgres database connection name | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
| V4_CFG_POSTGRES_SERVICE_ACCOUNT | Existing service account for postgres connectivity | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |

## CAS

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_RAM | Amount of ram to allocate to per CAS node | string | | false | Numeric value followed by the units, such as 32Gi for 32 gigabytes. In Kubernetes, the units for gigabytes is Gi. Leave empty to enable auto-resource assignment | viya |
| V4_CFG_CAS_CORES | Amount of cpu cores to allocate per CAS node | string | | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores. Leave empty to enable auto-resource assignment | viya |
| V4_CFG_CAS_WORKER_COUNT | Number of CAS workers | int | 1 | false | Setting to more than one triggers MPP deployment | viya |
| V4_CFG_CAS_ENABLE_BACKUP_CONTROLLER | Enable backup cas controller | bool | false | false | | viya |
| V4_CFG_CAS_ENABLE_LOADBALANCER | Setup LB to access CAS binary ports | bool | false | false | | viya |

## CONNECT

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONNECT_ENABLE_LOADBALANCER | Setup LB to access SAS/CONNECT | bool | false | false | | viya |
| V4_CFG_CONNECT_FQDN | FQDN that will be assigned to access SAS/CONNECT | string | | false | Required when V4_CFG_TLS_MODE is not disabled and cert-manager is used to issue TLS certificates. This FQDN will be added to the SAN DNS list of the issued certificates. | viya |

## Miscellaneous

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EMBEDDED_LDAP_ENABLE | Deploy openldap in the namespace for authentication | bool | false | false | [Openldap Config](../roles/vdm/templates/generators/openldap-bootstrap-config.yaml) | viya |
| V4_CFG_CONSUL_ENABLE_LOADBALANCER | Setup LB to access consul ui | bool | false | false | Consul ui port is 8500 | viya |
| V4_CFG_ELASTICSEARCH_ENABLE | Enable opendistro elasticsearch | bool | true | false | When deploying LTS less than 2020.1 or Stable less than 2020.1.2 set to false | viya |
