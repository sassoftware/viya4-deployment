# List of valid configuration variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

- [List of valid configuration variables](#list-of-valid-configuration-variables)
  - [BASE](#base)
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
  - [Postgres](#postgres)
  - [CAS](#cas)
  - [CONNECT](#connect)
  - [Miscellaneous](#miscellaneous)
  - [3rd Party tools](#3rd-party-tools)
    - [Cert-manager](#cert-manager)
    - [Cluster Autoscaler](#cluster-autoscaler)
    - [Ingress-nginx](#ingress-nginx)
    - [Metrics Server](#metrics-server)
    - [NFS Client](#nfs-client)
  - [Multi-Tenancy](#multi-tenancy)

## BASE

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy or stop at generating kustomize and manifest | bool | true | false | | viya |
| LOADBALANCER_SOURCE_RANGES | IPs to allow to ingress | [string] | | true | When deploying in the cloud, be sure to add the cloud nat ip | baseline, viya |
| BASE_DIR | Path to store persistent files | string | $HOME | false | | all |
| KUBECONFIG | Path to kubeconfig file | string | | true | | viya |
| V4_CFG_SITEDEFAULT | Path to sitedefault file | string | | false | When not set [sitedefault](../examples/sitedefault.yaml) is used | viya |
| V4_CFG_SSSD | Path to sssd file | string | | false | | viya |
| DEPLOYMENT_OPERATOR_ENABLED | Is the SAS Deployment Operator present in the cluster | bool | false | false | | viya |

## Cloud

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, viya |
| CLUSTER_NAME | Name of the k8s cluster | string | | true | | baseline, viya |
| NAMESPACE | K8s namespace in which to deploy | string | | true | | baseline, viya, viya-monitoring |

### Authentication

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME | Cloud service account | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH | Full path to service account credentials file | string | | false | See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |

## Jump Server
Tool uses the jump server to interact with rwx filestore, that needs to be pre-mounted to JUMP_SVR_RWX_FILESTORE_PATH, when V4_CFG_MANAGE_STORAGE is set true.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| JUMP_SVR_HOST | ip/fqn to the jump host | string | | true | | baseline, viya |
| JUMP_SVR_USER | ssh user to access the jump host | string | | true | | baseline, viya |
| JUMP_SVR_PRIVATE_KEY | Path to ssh user private key to access the jump host | string |  | true | | baseline, viya |
| JUMP_SVR_RWX_FILESTORE_PATH | Path on jump server to nfs mount | string | /viya-share | false | | viya |

## Storage

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_MANAGE_STORAGE | Should the tool manage the storageclass | bool | true | false | Set to false if you wish to manage the storage class | all |
| V4_CFG_STORAGECLASS | Storageclass name | string | "sas" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting storage class that supports ReadWriteMany | baseline, viya |

### RWX Filestore

| Name | Description | Type | Default | Required | Notes | Tasks |
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

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ORDER_NUMBER | SAS order number | string | | true | | viya |
| V4_CFG_CADENCE_NAME | Cadence name | string | lts | false | [stable,lts] | viya |
| V4_CFG_CADENCE_VERSION | Cadence version | string | 2020.1 | true | | viya |
| V4_CFG_DEPLOYMENT_ASSETS | Path to pre-downloaded deployment assets | string | | false | Leave blank to download deployment assets | viya |
| V4_CFG_LICENSE | Path to pre-downloaded license file | string | | false| Leave blank to download license file | viya |

## SAS API Access

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_API_KEY | SAS API Key| string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |
| V4_CFG_SAS_API_SECRET | SAS API Secret | string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |

## Container Registry Access

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | false | By default, credentials are already included in the downloaded deploymentAssets | viya |
| V4_CFG_CR_PASSWORD | Container registry password | string | | false | By default, credentials are already included in the downloaded deploymentAssets | viya |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | | viya |

## Ingress

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | Which ingress controller to deploy | string | "ingress" | true | Possible values: "ingress" | baseline, viya |
| V4_CFG_INGRESS_FQDN | FQDN to for viya installation | string | | true | | viya |
| V4_CFG_INGRESS_MODE | Public vs. Private Loadbalancer endpoint | string | "public" | false | Possible values: "public", "private". Setting this option to "private" adds options to the Ingress Controller that create a LoadBalancer with private IP(s) only. | baseline |

## Monitoring and Logging

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_VERSION | Branch or tag of [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) | string | stable | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_BASE_DOMAIN | Base domain in which subdomains for search, dashboards, grafana, prometheus and alertmanager will be created | string | | false | This or the per service fqdn's must be set | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_CERT | Path to tls certificate to use for all monitoring/logging services | string | | false | Alternately you can set the per service cert | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_KEY | Path to tls key to use for all monitoring/logging services | string | | false | Alternately you can set the per service cert | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_NODE_PLACEMENT_ENABLE | Enable workload node placement for viya4-monitoring-kubernetes stack | bool | false | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_STORAGECLASS | Storageclass name | string | v4m | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your pre-existing storage class that supports ReadWriteOnce | cluster-logging, cluster-monitoring, viya-monitoring |

### Monitoring

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_MONITORING_NAMESPACE | Namespace for the monitoring resources | string | monitoring | false | | cluster-monitoring |
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

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_LOGGING_NAMESPACE | Namespace for the logging resources | string | logging | false | | cluster-logging |
| V4M_KIBANA_FQDN | FQDN to use for dashboards ingress | string | dashboards.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_KIBANA_CERT | Path to tls certificate to use for dashboards ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-logging |
| V4M_KIBANA_KEY | Path to tls key to use for dashboards ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-logging |
| V4M_KIBANA_PASSWORD | Dashboards admin password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-logging |
| V4M_KIBANA_LOGADM_PASSWORD | Dashboards logadm user's password | string | randomly generated | false | If not provided and V4M_KIBANA_PASSWORD is not set, a random password will be generated and written to the log output | cluster-logging |
| V4M_KIBANASERVER_PASSWORD | Dashboards server password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-logging |
| V4M_LOGCOLLECTOR_PASSWORD | Logcollector password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-logging |
| V4M_METRICGETTER_PASSWORD | Metricgetter password | string | randomly generated | false | If not provided, a random password will be generated and written to the log output | cluster-logging |
| | | | | | | |
| V4M_ELASTICSEARCH_FQDN | FQDN to use for search ingress  | string | search.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_ELASTICSEARCH_CERT | Path to tls certificate to use for search ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed cert will be used | cluster-logging |
| V4M_ELASTICSEARCH_KEY | Path to tls key to use for search ingress | string | <V4M_KEY> | false | If both this and V4M_KEY are not set a self-signed cert will be used | cluster-logging |
| V4M_OSD_NODEPORT_ENABLE |  If you want to make OpenSearch Dashboards accessible via NodePort, set the environment variable V4M_OSD_NODEPORT_ENABLE to true. OpenSearch Dashboards will be accessible from port 31034 | bool | false | false | | cluster-logging

## TLS

Viya 4 supports 2 different types of certificate generators, cert-manager and openssl.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_TLS_GENERATOR | Which tool to use for certificate generation | string | openssl | false | Supported values: [`cert-manager`,`openssl`]. | viya, cluster-logging, cluster-monitoring |
| V4_CFG_TLS_MODE | Which TLS mode to configure | string | front-door | false | Supported values: [`full-stack`,`front-door`,`disabled.`] When deploying full-stack you must set V4_CFG_TLS_TRUSTED_CA_CERTS to trust external postgres server ca. | all |
| V4_CFG_TLS_CERT | Path to ingress certificate file | string | | false | If specified, used instead of cert-manager issued certificates | viya |
| V4_CFG_TLS_KEY | Path to ingress key file | string | | false | Required when V4_CFG_TLS_CERT is specified | viya |
| V4_CFG_TLS_TRUSTED_CA_CERTS | Path to directory containing only PEM encoded trusted CA certificates files | string | | false | Required when V4_CFG_TLS_CERT is specified. Must include all the CAs in the trust chain for V4_CFG_TLS_CERT. Can be used with or without V4_CFG_TLS_CERT to specify any additionally trusted CAs  | viya |
| V4_CFG_TLS_DURATION | Certificate time to expiry in hours | int | 17531 | false | See note below | viya |
| V4_CFG_TLS_ADDITIONAL_SAN_DNS | A space separated list of additional SAN DNS entries that you want added to generated certificates. | string | | false | See note below  | viya |
| V4_CFG_TLS_ADDITIONAL_SAN_IP | A space separated list of additional SAN IP addresses that you want added to generated certificates. | string | | false | See note below  | viya |

Notes:

*Values can be used to configure the tls generator when V4_CFG_TLS_MODE is not set to `disabled` and one of the following conditions is met.*
  - V4_CFG_TLS_GENERATOR is set to `cert-manager` and no V4_CFG_TLS_CERT/V4_CFG_TLS_KEY are defined
  - V4_CFG_TLS_GENERATOR is set to `openssl` and no V4_CFG_TLS_CERT/V4_CFG_TLS_KEY are defined

## Postgres

Postgres servers can be defined with the postgres_servers variable which is a map of objects. The variable has the following format:

```bash
V4_CFG_POSTGRES_SERVERS:
  default:
    ...
  other_server:
    ...
  ...
```

**NOTE**: the `default` elements is always required . This will be the default server. Below is the list of parameters each element can contain.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| internal | Whether the database is internal or external | bool | | true | All servers must either be internal or all must be external | viya |
| database | Database name | string | Database server role | false | Default database name for default server is SharedServices | viya |
| admin | External postgres username | string | | false | Required for external postgres servers | viya |
| password | External postgres password | string | | false | Required for external postgres servers | viya |
| fqdn | External postgres ip/fqdn | string | | false | Required for external postgres servers | viya |
| server_port | External postgres port | string | 5432 | false | | viya |
| ssl_enforcement_enabled | Require ssl connection to external postgres | bool | | false | Required for external postgres servers. Ignored on GCP when using cloud sql | viya |
| connection_name | External postgres database connection name | string | | false | Required for using cloud-sql-proxy on gcp. See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
| service_account | External service account for postgres connectivity | string | | false | Required for using cloud-sql-proxy on gcp. See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |

Example:

```bash
V4_CFG_POSTGRES_SERVERS:
  default:
    internal: false
    admin: pgadmin
    password: "password"
    fqdn: mydbserver.local
    server_port: 5432
    ssl_enforcement_enabled: true
    database: SharedServices
  other_db:
    internal: false
    admin: pgadmin
    password: "password"
    fqdn: 10.10.10.10
    server_port: 5432
    ssl_enforcement_enabled: true
    database: OtherDB
```

## CAS

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_RAM | Amount of ram to allocate to per CAS node | string | | false | Numeric value followed by the units, such as 32Gi for 32 gigabytes. In Kubernetes, the units for gigabytes is Gi. Leave empty to enable auto-resource assignment | viya |
| V4_CFG_CAS_CORES | Amount of cpu cores to allocate per CAS node | string | | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores. Leave empty to enable auto-resource assignment | viya |
| V4_CFG_CAS_WORKER_COUNT | Number of CAS workers | int | 1 | false | Setting to more than one triggers MPP deployment | viya |
| V4_CFG_CAS_ENABLE_BACKUP_CONTROLLER | Enable backup cas controller | bool | false | false | | viya |
| V4_CFG_CAS_ENABLE_LOADBALANCER | Setup LB to access CAS binary ports | bool | false | false | | viya |

## CONNECT

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONNECT_ENABLE_LOADBALANCER | Setup LB to access SAS/CONNECT | bool | false | false | | viya |
| V4_CFG_CONNECT_FQDN | FQDN that will be assigned to access SAS/CONNECT | string | | false | Required when V4_CFG_TLS_MODE is not disabled and cert-manager is used to issue TLS certificates. This FQDN will be added to the SAN DNS list of the issued certificates. | viya |

## Miscellaneous

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLUSTER_NODE_POOL_MODE | What mode of cluster node pool to use | string | "standard" | false | [standard, minimal] | viya |
| V4_CFG_EMBEDDED_LDAP_ENABLE | Deploy openldap in the namespace for authentication | bool | false | false | [Openldap Config](../roles/vdm/templates/generators/openldap-bootstrap-config.yaml) | viya |
| V4_CFG_CONSUL_ENABLE_LOADBALANCER | Setup LB to access consul ui | bool | false | false | Consul ui port is 8500 | viya |
| V4_CFG_ELASTICSEARCH_ENABLE | Enable opendistro search | bool | true | false | When deploying LTS less than 2020.1 or Stable less than 2020.1.2 set to false | viya |

## 3rd Party tools

### Cert-manager

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CERT_MANAGER_ENABLED | Whether to deploy cert-manager into the cluster using helm | bool | false | false | Required if V4_CFG_TLS_GENERATOR is set to `cert-manager` and it's not already installed | baseline |
| CERT_MANAGER_NAMESPACE | cert-manager helm install namespace | string | cert-manager | false | | baseline |
| CERT_MANAGER_CHART_URL | cert-manager helm chart url | string | https://charts.jetstack.io/ | false | | baseline |
| CERT_MANAGER_CHART_NAME| cert-manager helm chart name | string | cert-manager| false | | baseline |
| CERT_MANAGER_CHART_VERSION | cert-manager helm chart version | string | 1.7.2 | false | | baseline |
| CERT_MANAGER_CONFIG | cert-manager helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |

### Cluster Autoscaler

Cluster-autoscaler is currently only used for AWS EKS clusters. GCP GKE and Azure AKS already have autoscaling features enabled by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CLUSTER_AUTOSCALER_ENABLED | Whether to deploy tool | bool | true | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_URL | cluster-autoscaler helm chart url | string | https://kubernetes.github.io/autoscaler | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_NAME| cluster-autoscaler helm chart name | string | cluster-autoscaler | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_VERSION | cluster-autoscaler helm chart version | string | 9.9.2 | false | | baseline |
| CLUSTER_AUTOSCALER_CONFIG | cluster-autoscaler helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| CLUSTER_AUTOSCALER_ACCOUNT | cluster autoscaler aws role arn | string | | false | Required to enable cluster-autoscaler on AWS | baseline |
| CLUSTER_AUTOSCALER_LOCATION | aws region where kubernetes cluster resides | string | us-east-1 | false | | baseline |

### Ingress-nginx

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| INGRESS_NGINX_NAMESPACE | ingress-nginx helm install namespace | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_URL | ingress-nginx helm chart url | string | https://kubernetes.github.io/ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_NAME | ingress-nginx helm chart name | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_VERSION | ingress-nginx helm chart version | string | "" | false | If left as "" (empty string), version 3.40.0 will be used for K8s clusters whose version is <= 1.21.X and version 4.0.17 will be used for K8s clusters whose version is >= 1.22.X| baseline |
| INGRESS_NGINX_CONFIG | ingress-nginx helm values | string | see [here](../roles/baseline/defaults/main.yml) Altering this value will affect the cluster | false | | baseline |

### Metrics Server

Metric server is currently only used for AWS EKS clusters. GCP GKE and Azure AKS already have a metric server provided by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| METRICS_SERVER_ENABLED | Whether to deploy tool | bool | true | false | | baseline |
| METRICS_SERVER_CHART_URL | metrics-server helm chart url | string | https://charts.bitnami.com/bitnami/ | false | If an existing metric-server is installed, these options will be ignored | baseline |
| METRICS_SERVER_CHART_NAME | metrics-server helm chart name | string | metrics-server | false | If an existing metric-server is installed, these options will be ignored | baseline |
| METRICS_SERVER_CHART_VERSION | metrics-server helm chart version | string | 5.11.7 | false | If an existing metric-server is installed, these options will be ignored | baseline |
| METRICS_SERVER_CONFIG | metrics-server helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | If an existing metric-server is installed, these options will be ignored | baseline |

### NFS Client

The nfs-client is currently supported by the newer nfs-subdir-external-provisioner.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| NFS_CLIENT_NAMESPACE | nfs-subdir-external-provisioner helm install namespace | string | nfs-client | false | | baseline |
| NFS_CLIENT_CHART_URL | nfs-subdir-external-provisioner helm chart url | string | https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ | false | | baseline |
| NFS_CLIENT_CHART_NAME | nfs-subdir-external-provisioner helm chart name | string | nfs-subdir-external-provisioner | false | | baseline |
| NFS_CLIENT_CHART_VERSION | nfs-subdir-external-provisioner helm chart version | string | 4.0.8| false | | baseline |
| NFS_CLIENT_CONFIG | nfs-subdir-external-provisioner helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |

## Multi-Tenancy

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4MT_ENABLE | Enables Multi-tenancy in the SAS Viya deployment | bool | false | false || viya, multi-tenancy |
| V4MT_MODE | Set V4MT_MODE to either schema or database | string | schema | false | Two modes of data isolation (schemaPerApplicationTenant, databasePerTenant) for tenant data. schemaPerApplicationTenant is default.  | viya, multi-tenancy |
| V4MT_TENANT_IDS | Maps to SAS_TENANT_IDS. One or more tenant IDs to onboard or offboard | string | | false | Example: Single tenant ID: "acme" or Multiple tenant IDs: "acme, cyberdyne, intech" | viya, multi-tenancy |
| V4MT_PROVIDER_PASSWORD | Optional: The password that is applied to the tenant administrator on each onboarded tenant | string | | false | Maps to SAS_PROVIDER_PASSWORD. When V4MT_PROVIDER_PASSWORD is specified V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} can not be used. See details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#p1ghvmezrb3cvxn1h7vg4uguqct6) | multi-tenancy |
| V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} | Optional: Unique sasprovider password for each tenant being onboarded. {{TENANT-ID}} must be in uppercase | string | | false | Maps to SAS_PROVIDER_PASSWORD_{{TENANT-ID}}. When V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} is specified V4MT_PROVIDER_PASSWORD can not be used. See details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#p1ghvmezrb3cvxn1h7vg4uguqct6) | multi-tenancy |
| V4MT_CAS_WORKER_COUNT | The number of CAS worker nodes for tenants. Default is 0 (SMP) | int | 0 | false | | multi-tenancy |
| V4MT_CAS_BACKUP | Set this flag to 1 to include a CAS backup controller | int | Disabled by default | false | | multi-tenancy |