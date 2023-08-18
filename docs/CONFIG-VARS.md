# List of Valid Configuration Variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

- [List of Valid Configuration Variables](#list-of-valid-configuration-variables)
  - [BASE](#base)
  - [Cloud](#cloud)
    - [Authentication](#authentication)
  - [Jump Server](#jump-server)
  - [Storage](#storage)
    - [RWX Filestore](#rwx-filestore)
    - [Azure](#azure)
    - [AWS](#aws)
    - [GCP](#gcp)
  - [SAS Software Order](#sas-software-order)
  - [SAS API Access](#sas-api-access)
  - [Container Registry Access](#container-registry-access)
  - [Ingress](#ingress)
  - [Monitoring and Logging](#monitoring-and-logging)
    - [Monitoring](#monitoring)
    - [Logging](#logging)
  - [TLS](#tls)
  - [PostgreSQL](#postgresql)
  - [CAS](#cas)
  - [CONNECT](#connect)
  - [Miscellaneous](#miscellaneous)
  - [Third-Party Tools](#third-party-tools)
    - [Cert-manager](#cert-manager)
    - [Cluster Autoscaler](#cluster-autoscaler)
    - [EBS CSI Driver](#ebs-csi-driver)
    - [Ingress-nginx](#ingress-nginx)
    - [Metrics Server](#metrics-server)
    - [NFS Client](#nfs-client)
    - [Postgres NFS Client](#postgres-nfs-client)
  - [Multi-tenancy](#multi-tenancy)

## BASE

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy the SAS Viya platform and SAS Viya Platform Deployment Operator or stop at generating kustomization.yaml and manifests | bool | true | false | This flag can also prevent the uninstall of both the SAS Viya platform and SAS Viya Platform Deployment Operator | viya |
| LOADBALANCER_SOURCE_RANGES | IP addresses to allow to reach the ingress | [string] | | true | When deploying in a cloud environment, be sure to add the cloud NAT IP address. | baseline, viya |
| BASE_DIR | Path to store persistent files | string | $HOME | false | | all |
| KUBECONFIG | Path to kubeconfig file | string | | true | | viya |
| V4_CFG_SITEDEFAULT | Path to sitedefault file | string | | false | When not set, [sitedefault](../examples/sitedefault.yaml) is used. | viya |
| V4_CFG_SSSD | Path to sssd file | string | | false | | viya |
| V4_DEPLOYMENT_OPERATOR_ENABLED | Whether to install the [SAS Viya Platform Deployment Operator](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm) in the cluster and use it to deploy the SAS Viya platform | bool | true | false | If this value is set to false, the [sas-orchestration command](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=p0839p972nrx25n1dq264egtgrcq.htm) is instead used to deploy SAS Viya. | viya |
| V4_DEPLOYMENT_OPERATOR_SCOPE | Where the SAS Viya Platform Deployment Operator should watch for SASDeployments | string | "cluster" | false | [namespace, cluster] [Additional documentation](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n137b56hwogd7in1onzys95awxqe.htm#p16ayulwlsuw8vn10bkpsjtw1ldg) describing these options is available. | viya |
| V4_DEPLOYMENT_OPERATOR_NAMESPACE | Namespace where the SAS Viya Platform Deployment Operator should be installed  | string | "sasoperator" | false | Only applicable when V4_DEPLOYMENT_OPERATOR_SCOPE="cluster". | viya |
| V4_DEPLOYMENT_OPERATOR_CRB | Name of the ClusterRoleBinding resource that is needed by the SAS Viya Platform Deployment Operator | string | "sasoperator" | false | [Additional documentation](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n137b56hwogd7in1onzys95awxqe.htm#p1arr91os91cg5n1tsmuamj6h10g) describing the resource is available. | viya |

**SAS Viya Platform Deployment Operator Notes:**

* Currently, the viya4-deployment project does not support using the SAS Viya Platform Deployment Operator in conjunction with a Long-Term Support: 2021.1 deployment that uses an alternate mirror repository (`V4_CFG_CR_URL`).

* In a scenario where you have multiple SAS Viya platform deployments managed by a single cluster-wide deployment operator, uninstalling one of the SAS Viya platform deployments does not remove the SAS Viya Deployment Operator from the cluster. However, during the uninstallation workflow, if no SAS Viya platform deployments that are managed by the cluster-wide deployment operator are detected, the SAS Viya Deployment Operator is also removed.

* If you are running this project using Ansible directly on your workstation, we require Docker to be installed and the executing user should be able to access it. This is required to use the sas-orchestration command. See [ansible usage](user/AnsibleUsage.md#Preparation).

* Using the sas-orchestration deploy command to perform a SAS Viya platform deployment is only applicable for SAS Viya 2022.12 and later. For previous releases, use the SAS Viya Platform Deployment Operator to perform your deployments.

## Cloud

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, viya |
| CLUSTER_NAME | Name of the Kubernetes cluster | string | | true | | baseline, viya |
| NAMESPACE | Kubernetes namespace in which to deploy | string | | true | | baseline, viya, viya-monitoring |

### Authentication

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME | Cloud service account | string | | false | See [Ansible Cloud Authentication](user/AnsibleCloudAuthentication.md) for more information. | viya |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH | Full path to service account credentials file | string | | false | See [Ansible Cloud Authentication](user/AnsibleCloudAuthentication.md) for more information. | viya |

## Jump Server
Viya4-deployment uses the jump server to interact with the RWX filestore, which must be pre-mounted to `JUMP_SVR_RWX_FILESTORE_PATH` when `V4_CFG_MANAGE_STORAGE` is set to `true`.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| JUMP_SVR_HOST | IP address or FQDN for the jump server host | string | | true | | baseline, viya |
| JUMP_SVR_USER | SSH user to access the jump server host | string | | true | | baseline, viya |
| JUMP_SVR_PRIVATE_KEY | Path to the SSH user's private key to access the jump server host | string |  | true | | baseline, viya |
| JUMP_SVR_RWX_FILESTORE_PATH | Path on the jump server to the NFS mount | string | /viya-share | false | | viya |

## Storage
When `V4_CFG_MANAGE_STORAGE` is set to `true`, viya4-deployment creates the `sas` and `pg-storage` storage classes using the nfs-subdir-external-provisioner Helm chart. If a jump server is used, viya4-deployment uses that server to create the folders for the `astores`, `bin`, `data` and `homes` RWX Filestore NFS paths that are outlined below in the [RWX Filestore](#rwx-filestore) section.

When `V4_CFG_MANAGE_STORAGE` is set to `false`, viya4-deployment does not create the `sas` or `pg-storage` storage classes for you. In addition, viya4-deployment does not create or manage the RWX Filestore NFS paths. Before you run the SAS Viya deployment, you must set the values for `V4_CFG_RWX_FILESTORE_ASTORES_PATH`, `V4_CFG_RWX_FILESTORE_BIN_PATH`, `V4_CFG_RWX_FILESTORE_DATA_PATH` and `V4_CFG_RWX_FILESTORE_HOMES_PATH` to specify existing NFS folder locations. The viya4-deployment user can create the required NFS folders from the jump server before starting the deployment. Recommended attribute settings for each folder are as follows:
- **filemode**: `0777`
- **group**: the equivalent of `nogroup` for your operating system
- **owner**: `nobody`

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_MANAGE_STORAGE | Whether viya4-deployment should manage the StorageClass | bool | true | false | Set to false if you want to manage the StorageClass yourself. | all |
| V4_CFG_STORAGECLASS | StorageClass name | string | "sas" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting StorageClass that supports ReadWriteMany. | baseline, viya |

### RWX Filestore

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_RWX_FILESTORE_ENDPOINT | NFS IP address or host name | string | | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_PATH | NFS export path | string | /export | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_ASTORES_PATH | NFS path to astores directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/astores | false | | viya |
| V4_CFG_RWX_FILESTORE_BIN_PATH | NFS path to bin directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/bin | false | | viya |
| V4_CFG_RWX_FILESTORE_DATA_PATH | NFS path to data directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/data | false | | viya |
| V4_CFG_RWX_FILESTORE_HOMES_PATH | NFS path to homes directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/homes | false | | viya |

### Azure

When V4_CFG_MANAGE_STORAGE is set to `true`, the `sas` and `pg-storage` storage classes are created (Azure NetApp or NFS).

### AWS

When V4_CFG_MANAGE_STORAGE is set to `true`, the efs-provisioner is deployed, the `sas` and `pg-storage` storage classes are created (EFS or NFS).

### GCP

When V4_CFG_MANAGE_STORAGE is set to `true`, the `sas` and `pg-storage` storage classes are created (Google Filestore or NFS).

## SAS Software Order

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ORDER_NUMBER | SAS software order ID | string | | true | | viya |
| V4_CFG_CADENCE_NAME | Cadence name | string | lts | false | [stable,lts] | viya |
| V4_CFG_CADENCE_VERSION | Cadence version | string | "2022.09" | true | This value must be surrounded by quotation marks to accommodate the updated SAS Cadence Version format. If the value is not quoted the deployment will fail. | viya |
| V4_CFG_DEPLOYMENT_ASSETS | Path to pre-downloaded deployment assets | string | | false | Leave blank to download [deployment assets](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopscon/n08bpieatgmfd8n192cnnbqc7m5c.htm#n1x7yoeafv23xan1gew0gfipt9e9) | viya |
| V4_CFG_LICENSE | Path to pre-downloaded license file | string | | false| Leave blank to download the [license file](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopscon/n08bpieatgmfd8n192cnnbqc7m5c.htm#p1odbfo85cz4r5n1j2tzx9zz9sbi) | viya |
| V4_CFG_CERTS | Path to pre-downloaded certificates file | string | | false| Leave blank to download the [certificates file](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopscon/n08bpieatgmfd8n192cnnbqc7m5c.htm#n0pj0ewyle0gfkn1psri3kw5ghha) | viya |

## SAS API Access

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_API_KEY | SAS API Key| string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |
| V4_CFG_SAS_API_SECRET | SAS API Secret | string | | true | [API credentials](https://developer.sas.com/guides/sas-viya-orders.html) can be obtained from the [SAS API Portal](https://apiportal.sas.com/get-started) | viya |

## Container Registry Access

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | false | By default, credentials are included in the downloaded deployment assets. | viya |
| V4_CFG_CR_PASSWORD | Container registry password | string | | false | By default, credentials are included in the downloaded deployment assets. | viya |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | | viya |

## Ingress

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | The ingress controller to deploy | string | "ingress" | true | Possible values: "ingress" | baseline, viya |
| V4_CFG_INGRESS_FQDN | FQDN to the ingress for SAS Vya installation | string | | true | | viya |
| V4_CFG_INGRESS_MODE | Whether to create a public or private Loadbalancer endpoint | string | "public" | false | Possible values: "public", "private". Setting this option to "private" adds options to the ingress controller that create a LoadBalancer with private IP address(es) only. | baseline |

## Monitoring and Logging

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_VERSION | Branch or tag of [viya4-monitoring-kubernetes](https://github.com/sassoftware/viya4-monitoring-kubernetes) | string | stable | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_BASE_DOMAIN | Base domain in which subdomains for search, dashboards, Grafana, Prometheus, and Alertmanager are created | string | | false | This parameter or the per-service FQDNs must be set. | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_CERT | Path to TLS certificate to use for all monitoring/logging services | string | | false | As an alternative, you can set the per-service certificate. | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_KEY | Path to TLS key to use for all monitoring/logging services | string | | false | As an alternative, you can set the per-service certificate. | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_NODE_PLACEMENT_ENABLE | Whether to enable workload node placement for viya4-monitoring-kubernetes stack | bool | false | false | | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_STORAGECLASS | StorageClass name | string | v4m | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your pre-existing StorageClass that supports ReadWriteOnce. | cluster-logging, cluster-monitoring, viya-monitoring |
| V4M_ROUTING | Which routing type to use for viya4-monitoring-kubernetes applications | string | host-based | false | Supported values: [`host-based`, `path-based`] For host-based routing, the application name is part of the host name itself `https://dashboards.host.cluster.example.com/` For path-based routing, the host name is fixed and the application name is appended as a path on the URL `https://host.cluster.example.com/dashboards` | cluster-logging, cluster-monitoring |
| V4M_CUSTOM_CONFIG_USER_DIR | Path to the viya4-monitoring-kubernetes top-level `USER_DIR` folder on the local file system. The `USER_DIR` folder can contain a top-level `user.env` file and `logging` and `monitoring` folders where your logging and monitoring `user.env` and customization yaml files are located. **NOTE**: viya4-monitoring does not validate `user.env` or yaml file content pointed to by this variable. It is recommended to use file content that has been verified ahead of time. | string | null | false | The following V4M configuration variables are ignored by viya4-monitoring when `V4M_CUSTOM_CONFIG_USER_DIR` is set: [`V4M_ROUTING`, `V4M_BASE_DOMAIN`, all `V4M_*_FQDN` variables,  all `V4M_*_PASSWORD` variables] [Additional documentation](https://go.documentation.sas.com/doc/en/obsrvcdc/v_001/obsrvdply/n0wgd3ju667sa9n1adnxs7hnsqt6.htm) describing the `USER_DIR` folder is available.| cluster-logging, cluster-monitoring

#### Open Source Kubernetes

When deploying `cluster-logging` or `cluster-monitoring` applications to kubernetes cluster infrastructure provisioned with the [Open Source Kubernetes viya4-iac-k8s](https://github.com/sassoftware/viya4-iac-k8s) project, you must explicitly set the value for `V4M_STORAGECLASS` to a pre-existing Storage Class (for example: `local-storage`)  regardless of the value set for `V4_CFG_MANAGE_STORAGE`. While other storage classes can be used, the `local-storage` class is **recommended** for the Viya Monitoring and Loggging tools.

### Monitoring

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_MONITORING_NAMESPACE | Namespace for the monitoring resources | string | monitoring | false | | cluster-monitoring |
| V4M_PROMETHEUS_FQDN | FQDN to use for Prometheus ingress | string | prometheus.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_PROMETHEUS_CERT | Path to TLS certificate to use for Prometheus ingress | string |<V4M_CERT> | false | If neither this variable nor V4M_CERT is set, a self-signed certificate is used. | cluster-monitoring |
| V4M_PROMETHEUS_KEY | Path to TLS key to use for Prometheus ingress | string | <V4M_KEY> | false | If neither this variable nor V4M_KEY is set, a self-signed certificate is used. | cluster-monitoring |
| | | | | | | |
| V4M_GRAFANA_FQDN | FQDN to use for Grafana ingress | string | grafana.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_GRAFANA_CERT | Path to TLS certificate to use for Grafana ingress | string |<V4M_CERT> | false | If neither this variable nor V4M_CERT is set, a self-signed certificate is used. | cluster-monitoring |
| V4M_GRAFANA_KEY | Path to TLS key to use for Grafana ingress | string | <V4M_KEY> | false | If neither this variable nor V4M_KEY is set, a self-signed certificate is used. | cluster-monitoring |
| V4M_GRAFANA_PASSWORD | Grafana administrator password | string | randomly generated | false | If not provided, a random password is generated and written to the log output. | cluster-monitoring |
| | | | | | | |
| V4M_ALERTMANAGER_FQDN | FQDN to use for Alertmanager ingress | string | alertmanager.<V4M_BASE_DOMAIN> | false | | cluster-monitoring |
| V4M_ALERTMANAGER_CERT | Path to TLS certificate to use for Alertmanager ingress | string |<V4M_CERT> | false | If neither this variable nor V4M_CERT is set, a self-signed certificate is used. | cluster-monitoring |
| V4M_ALERTMANAGER_KEY | Path to TLS key to use for Alertmanager ingress | string | <V4M_KEY> | false | If neither this variable nor V4M_KEY is set, a self-signed certificate is used. | cluster-monitoring |

### Logging

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4M_LOGGING_NAMESPACE | Namespace for the logging resources | string | logging | false | | cluster-logging |
| V4M_KIBANA_FQDN | FQDN to use for OpenSearch Dashboards ingress | string | dashboards.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_KIBANA_CERT | Path to TLS certificate to use for OpenSearch Dashboards ingress | string |<V4M_CERT> | false | If neither this variable nor V4M_CERT is set, a self-signed certificate is used. | cluster-logging |
| V4M_KIBANA_KEY | Path to TLS key to use for OpenSearch Dashboards ingress | string | <V4M_KEY> | false | If neither this variable nor V4M_KEY is set, a self-signed certificate is used. | cluster-logging |
| V4M_KIBANA_PASSWORD | OpenSearch Dashboards administrator password | string | randomly generated | false | If not provided, a random password is generated and written to the log output. | cluster-logging |
| V4M_KIBANA_LOGADM_PASSWORD | OpenSearch Dashboards logadm user's password | string | randomly generated | false | If not provided, and if V4M_KIBANA_PASSWORD is not set, a random password is generated and written to the log output. | cluster-logging |
| V4M_KIBANASERVER_PASSWORD | OpenSearch Dashboards server password | string | randomly generated | false | If not provided, a random password is generated and written to the log output | cluster-logging |
| V4M_LOGCOLLECTOR_PASSWORD | Logcollector password | string | randomly generated | false | If not provided, a random password is generated and written to the log output | cluster-logging |
| V4M_METRICGETTER_PASSWORD | Metricgetter password | string | randomly generated | false | If not provided, a random password is generated and written to the log output | cluster-logging |
| | | | | | | |
| V4M_ELASTICSEARCH_FQDN | FQDN to use for OpenSearch ingress  | string | search.<V4M_BASE_DOMAIN> | false | | cluster-logging |
| V4M_ELASTICSEARCH_CERT | Path to TLS certificate to use for OpenSearch ingress | string |<V4M_CERT> | false | If both this and V4M_CERT are not set a self-signed certificate is used. | cluster-logging |
| V4M_ELASTICSEARCH_KEY | Path to TLS key to use for OpenSearch ingress | string | <V4M_KEY> | false | If neither this variable nor V4M_KEY is set, a self-signed certificate is used. | cluster-logging |

## TLS

The SAS Viya platform supports two certificate generators: cert-manager and openssl.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_TLS_GENERATOR | Which SAS-provided tool to use for certificate generation | string | openssl | false | Supported values: [`cert-manager`,`openssl`]. If set to `cert-manager`, `cert-manager` will be installed during baselining. | baseline, viya, cluster-logging, cluster-monitoring |
| V4_CFG_TLS_MODE | Which TLS mode to configure | string | front-door | false | Supported values: [`full-stack`,`front-door`,`disabled.`] When deploying full-stack you must set V4_CFG_TLS_TRUSTED_CA_CERTS to trust external postgres server ca. | all |
| V4_CFG_TLS_CERT | Path to ingress certificate file | string | | false | If specified, used instead of cert-manager issued certificates | viya |
| V4_CFG_TLS_KEY | Path to ingress key file | string | | false | Required when V4_CFG_TLS_CERT is specified | viya |
| V4_CFG_TLS_TRUSTED_CA_CERTS | Path to directory containing only PEM-encoded trusted CA certificate files | string | | false | Required when using an external database if TLS is enabled and the deployment target is an IaC-created AWS or open source Kubernetes cluster. See the [Trusted CA Certs](user/TrustedCACerts.md) document for information about AWS and open source Kubernetes certificates. Required when V4_CFG_TLS_CERT is specified. Must include all the CAs in the trust chain for V4_CFG_TLS_CERT. Can be used with or without V4_CFG_TLS_CERT to specify any additional trusted CAs.  | viya |
| V4_CFG_TLS_DURATION | Certificate time to expiry in hours | int | 17531 | false | See the note below. | viya |
| V4_CFG_TLS_ADDITIONAL_SAN_DNS | A space-separated list of additional SAN DNS entries to add to generated certificates. | string | | false | See the note below.  | viya |
| V4_CFG_TLS_ADDITIONAL_SAN_IP | A space-separated list of additional SAN IP addresses to add to generated certificates. | string | | false | See the note below.  | viya |

**Notes:**

*Values can be used to configure the TLS certificate generator when V4_CFG_TLS_MODE is not set to `disabled` and one of the following conditions is met:*
  - V4_CFG_TLS_GENERATOR is set to `cert-manager` and no V4_CFG_TLS_CERT/V4_CFG_TLS_KEY are defined
  - V4_CFG_TLS_GENERATOR is set to `openssl` and no V4_CFG_TLS_CERT/V4_CFG_TLS_KEY are defined

## PostgreSQL

PostgreSQL servers can be defined using the POSTGRES_SERVERS variable, which is a map of objects. The variable has the following format:

```bash
V4_CFG_POSTGRES_SERVERS:
  default:
    ...
  other_server:
    ...
  ...
```
Several SAS Viya platform offerings require a second internal Postgres instance referred to as SAS Common Data Store or CDS PostgreSQL. See details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p0wkxxi9s38zbzn19ukjjaxsc0kl). The list of software offerings that include CDS PostgreSQL is located at [SAS Common Data Store Requirements (for SAS Planning and Retail Offerings)](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopssr/p05lfgkwib3zxbn1t6nyihexp12n.htm#n03wzanutmc6gon1val5fykas9aa) in System Requirements for the SAS Viya platform. To deploy and configure a CDS PostgreSQL instance in addition to the default internal platform Postgres instance, specify "cds-postgres" for your second Postgres instance as shown in the example below:

```bash
V4_CFG_POSTGRES_SERVERS:
  default:
    internal: true
    ...
  cds-postgres:
    internal: true
    ...
  ...
```

**NOTE**: Below is the list of parameters each database element can contain.

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
| postgres_pvc_storage_size | Size of the internal postgreSQL PVCs | string | 128Gi | false |This value can be changed but not decreased after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases.| viya |
| backrest_pvc_storage_size | Size of the internal pgBackrest PVCs | string | 128Gi | false | This value can be changed but not decreased after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases.| viya |
| postgres_pvc_access_mode | Access mode for the PostgreSQL PVCs | string | ReadWriteOnce | false | Supported values: [`ReadWriteOnce`,`ReadWriteMany`]. This value cannot be changed after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases.| viya |
| backrest_pvc_access_mode | Access mode for the pgBackrest PVCs | string | ReadWriteOnce | false | Supported values: [`ReadWriteOnce`,`ReadWriteMany`]. This value cannot be changed after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases.| viya |
| postgres_storage_class | Storage class for the PostgreSQL PVCs | string | pg-storage | false |This value cannot be changed after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases. When `V4_CFG_MANAGE_STORAGE` is set to `true`, a storage class named `pg-storage` is created and is configured as the default storageClass. If `V4_CFG_MANAGE_STORAGE` is set to false, specify the name of an existing storage class for the value. | viya |
| backrest_storage_class | Storage class for the pgBackrest PVCs | string | pg-storage | false |This value cannot be changed after the initial deployment. Supported for cadence versions 2022.10 and later. Only for internal databases. When `V4_CFG_MANAGE_STORAGE` is set to `true`, a storage class named `pg-storage` is created and is configured as the default storageClass. If `V4_CFG_MANAGE_STORAGE` is set to false, specify the name of an existing storage class for the value. | viya |


**NOTE**: The `default` element is always required. This will be the default server.

Examples:

```bash
# Internal server
V4_CFG_POSTGRES_SERVERS:
  default:
    internal: true
    postgres_pvc_storage_size: 10Gi
    postgres_pvc_access_mode: ReadWriteOnce
    postgres_storage_class: pg-storage
    backrest_storage_class: pg-storage


# External servers
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
| V4_CFG_CAS_RAM | Amount of RAM to allocate to per CAS node | string | | false | Numeric value followed by the units, such as 32Gi for 32 gibibytes. In Kubernetes, the unit is Gi. Leave empty to enable auto-resource assignment. | viya |
| V4_CFG_CAS_CORES | Amount of CPU cores to allocate per CAS node | string | | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores. Leave empty to enable auto-resource assignment. | viya |
| V4_CFG_CAS_WORKER_COUNT | Number of CAS workers | int | 1 | false | Setting to more than one triggers MPP CAS deployment. | viya |
| V4_CFG_CAS_ENABLE_BACKUP_CONTROLLER | Enable backup CAS controller | bool | false | false | | viya |
| V4_CFG_CAS_ENABLE_LOADBALANCER | Set up LoadBalancer to access CAS binary ports | bool | false | false | | viya |
| V4_CFG_CAS_ENABLE_AUTO_RESTART | Include a transformer so that the CAS servers will automatically restart during version updates performed by the SAS Viya Deployment Operator. | bool | true | false | This variable will not be applicable if you are not using the SAS Viya Deployment Operator by setting `V4_DEPLOYMENT_OPERATOR_ENABLED` to "false". See the [SAS Viya Platform Operations documentation](https://go.documentation.sas.com/doc/en/itopscdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1mtzb2zsvv581n1gpmwds3urbon) for additional information. | viya |

## CONNECT

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONNECT_ENABLE_LOADBALANCER | Set up LoadBalancer to access SAS/CONNECT | bool | false | false | | viya |
| V4_CFG_CONNECT_FQDN | FQDN that is assigned to access SAS/CONNECT | string | | false | Required when V4_CFG_TLS_MODE is not disabled and cert-manager is used to issue TLS certificates. This FQDN is added to the SAN DNS list of the issued certificates. | viya |

## Miscellaneous

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLUSTER_NODE_POOL_MODE | The mode of cluster node pool to use | string | "standard" | false | [standard, minimal] | viya |
| V4_CFG_EMBEDDED_LDAP_ENABLE | Deploy OpenLDAP in the namespace for authentication | bool | false | false | [Openldap Config](../roles/vdm/templates/generators/openldap-bootstrap-config.yaml) | viya |
| V4_CFG_CONSUL_ENABLE_LOADBALANCER | Set up LoadBalancer to access the Consul user interface | bool | false | false | Consul UI port is 8500. | viya |
| V4_CFG_ELASTICSEARCH_ENABLE | Enable search with Open Distro for ElasticSearch | bool | true | false | When deploying LTS earlier than 2020.1 or Stable earlier than 2020.1.2, set to false. | viya |
| V4_CFG_VIYA_START_SCHEDULE | Configure your SAS Viya platform deployment to start on specific schedules | string |  | false | This variable accepts [CronJob schedule expressions](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax) to create your Viya start job schedule. See note below. | viya |
| V4_CFG_VIYA_STOP_SCHEDULE | Configure your SAS Viya platform deployment to stop on specific schedules | string |  | false | This variable accepts [CronJob schedule expressions](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax) to create your Viya stop job schedule. See note below. | viya |

Notes:
  - With the two Viya scheduling variables, `V4_CFG_VIYA_START_SCHEDULE` and `V4_CFG_VIYA_STOP_SCHEDULE`. If you define one and not the other, it will result in a suspended cronjob for the variable that was not defined.
    - For example, defining `V4_CFG_VIYA_STOP_SCHEDULE` and not `V4_CFG_VIYA_START_SCHEDULE` will result in a Viya stop job that runs on a schedule and a suspended Viya start job that you will be able to manually trigger.
  - Defining both `V4_CFG_VIYA_START_SCHEDULE` and `V4_CFG_VIYA_STOP_SCHEDULE` will result in a non-suspended Viya start and stop job that runs on the schedule you defined.

## Third-Party Tools

### Cert-manager

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CERT_MANAGER_NAMESPACE | cert-manager Helm installation namespace | string | cert-manager | false | | baseline |
| CERT_MANAGER_CHART_URL | cert-manager Helm chart URL | string | https://charts.jetstack.io/ | false | | baseline |
| CERT_MANAGER_CHART_NAME| cert-manager Helm chart name | string | cert-manager| false | | baseline |
| CERT_MANAGER_CHART_VERSION | cert-manager Helm chart version | string | 1.11.0 | false | | baseline |
| CERT_MANAGER_CONFIG | cert-manager Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |

Notes:
  - cert-manager will only be installed if `V4_CFG_TLS_GENERATOR` is set to "cert-manager"

### Cluster Autoscaler

Cluster-autoscaler is currently only used for AWS EKS clusters. GCP GKE and Azure AKS already have autoscaling features enabled by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CLUSTER_AUTOSCALER_ENABLED | Whether to deploy cluster-autoscaler | bool | true | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_URL | Cluster-autoscaler Helm chart URL | string | See [this document](https://github.com/kubernetes/autoscaler/tree/master/charts) for more information. | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_NAME| Cluster-autoscaler Helm chart name | string | cluster-autoscaler | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_VERSION | Cluster-autoscaler Helm chart version | string | "" | false | If left as "" (empty string), version 9.9.2 is used for Kubernetes clusters whose version is <= 1.21 <br> and version 9.29.1 is used for Kubernetes clusters whose version is >= 1.25 | baseline |
| CLUSTER_AUTOSCALER_CONFIG | Cluster-autoscaler Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |
| CLUSTER_AUTOSCALER_ACCOUNT | Cluster autoscaler AWS role ARN | string | | false | Required to enable cluster-autoscaler on AWS | baseline |
| CLUSTER_AUTOSCALER_LOCATION |AWS region where Kubernetes cluster is running | string | us-east-1 | false | | baseline |

**Cluster Autoscaler Notes:**

If you used [viya4-iac-aws:5.6.0](https://github.com/sassoftware/viya4-iac-aws/releases) or newer to create your infrastructure, a cluster autoscaler account should have been created for you with a policy that is compatible with both our default versions for the `CLUSTER_AUTOSCALER_CHART_VERSION` variable. If you choose an alternative version ensure that your autoscaler account has a policy that matches the recommendation from the [kubernetes/autoscaler documentation](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#iam-policy). This note is only applicable for EKS clusters.


### EBS CSI Driver

The EBS CSI driver is currently only used for kubernetes v1.23 or later AWS EKS clusters.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| EBS_CSI_DRIVER_CHART_URL | aws ebs csi driver helm chart url | string | https://kubernetes-sigs.github.io/aws-ebs-csi-driver | false | | baseline |
| EBS_CSI_DRIVER_CHART_NAME| aws ebs csi driver helm chart name | string | aws-ebs-csi-driver | false | | baseline |
| EBS_CSI_DRIVER_CHART_VERSION | aws ebs csi driver helm chart version | string | 2.11.1 | false | | baseline |
| EBS_CSI_DRIVER_CONFIG | aws ebs csi driver helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| EBS_CSI_DRIVER_ACCOUNT | cluster autoscaler aws role arn | string | | false | Required to enable the aws ebs csi driver on AWS | baseline |
| EBS_CSI_DRIVER_LOCATION | aws region where kubernetes cluster resides | string | us-east-1 | false | | baseline |

### Ingress-nginx

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| INGRESS_NGINX_NAMESPACE | NGINX Ingress Helm installation namespace | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_URL | NGINX Ingress Helm chart URL | string | See [this document](https://kubernetes.github.io/ingress-nginx) for more information. | false | | baseline |
| INGRESS_NGINX_CHART_NAME | NGINX Ingress Helm chart name | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_VERSION | NGINX Ingress Helm chart version | string | "" | false | If left as "" (empty string), version 4.3.0 is used for Kubernetes clusters whose version is <= 1.23.X, and version 4.7.1 is used for Kubernetes clusters whose version is >= 1.24.X. | baseline |
| INGRESS_NGINX_CONFIG | NGINX Ingress Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. Altering this value will affect the cluster. | false | | baseline |

### Metrics Server

Kubernetes Metrics Server installation is currently only applicable for AWS EKS clusters. GCP GKE and Azure AKS already have a metric server provided by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| METRICS_SERVER_ENABLED | Whether to deploy Metrics Server | bool | true | false | | baseline |
| METRICS_SERVER_CHART_URL | Metrics Server Helm chart url | string | Go [here](https://charts.bitnami.com/bitnami/) for more information. | false | If an existing Metrics Server is installed, these options are ignored. | baseline |
| METRICS_SERVER_CHART_NAME | Metrics Server Helm chart name | string | metrics-server | false | If an existing Metrics Server is installed, these options are ignored. | baseline |
| METRICS_SERVER_CHART_VERSION | Metrics Server Helm chart version | string | 6.2.4 | false | If an existing Metrics Server is installed, these options are ignored. | baseline |
| METRICS_SERVER_CONFIG | Metrics Server Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | If an existing Metrics Server is installed, these options are ignored. | baseline |

### NFS Client

The NFS client is currently supported by the newer nfs-subdir-external-provisioner.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| NFS_CLIENT_NAMESPACE | nfs-subdir-external-provisioner Helm installation namespace | string | nfs-client | false | | baseline |
| NFS_CLIENT_CHART_URL | nfs-subdir-external-provisioner Helm chart URL | string | Go [here](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/) for more information. | false | | baseline |
| NFS_CLIENT_CHART_NAME | nfs-subdir-external-provisioner Helm chart name | string | nfs-subdir-external-provisioner | false | | baseline |
| NFS_CLIENT_CHART_VERSION | nfs-subdir-external-provisioner Helm chart version | string | 4.0.18| false | | baseline |
| NFS_CLIENT_CONFIG | nfs-subdir-external-provisioner Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |

### Postgres NFS Client

The Postgres NFS client is currently supported by the nfs-subdir-external-provisioner. It creates the storage class used by 2022.10 and later internal postgres instances.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PG_NFS_CLIENT_NAMESPACE | nfs-subdir-external-provisioner Helm installation namespace | string | nfs-client | false | | baseline |
| PG_NFS_CLIENT_CHART_URL | nfs-subdir-external-provisioner Helm chart URL | string | Go [here](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/) for more information. | false | | baseline |
| PG_NFS_CLIENT_CHART_NAME | nfs-subdir-external-provisioner Helm chart name | string | nfs-subdir-external-provisioner | false | | baseline |
| PG_NFS_CLIENT_CHART_VERSION | nfs-subdir-external-provisioner Helm chart version | string | 4.0.18| false | | baseline |
| PG_NFS_CLIENT_CONFIG | nfs-subdir-external-provisioner Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |


## Multi-tenancy

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4MT_ENABLE | Enables multi-tenancy in the SAS Viya platform deployment | bool | false | false || viya, multi-tenancy |
| V4MT_MODE | Set V4MT_MODE to either schema or database | string | schema | false | Two modes of data isolation (schemaPerApplicationTenant, databasePerTenant) are supported for tenant data. The default is schemaPerApplicationTenant.  | viya, multi-tenancy |
| V4MT_TENANT_IDS | Maps to SAS_TENANT_IDS. One or more tenant IDs to onboard or offboard | string | | false | Example: Single tenant ID: "acme" or Multiple tenant IDs: "acme, cyberdyne, intech". Tenant IDs have a few naming restrictions, See the details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#n1fptbibrh96r8n1jy317onpjd8r) | viya, multi-tenancy |
| V4MT_PROVIDER_PASSWORD | Optional: The password that is applied to the tenant administrator on each onboarded tenant | string | | false | Maps to SAS_PROVIDER_PASSWORD. When V4MT_PROVIDER_PASSWORD is specified, V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} cannot be used. See details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#p1ghvmezrb3cvxn1h7vg4uguqct6). | multi-tenancy |
| V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} | Optional: Unique sasprovider password for each tenant being onboarded. {{TENANT-ID}} must be in uppercase. | string | | false | Maps to SAS_PROVIDER_PASSWORD_{{TENANT-ID}}. When V4MT_PROVIDER_PASSWORD_{{TENANT-ID}} is specified, V4MT_PROVIDER_PASSWORD cannot be used. See details [here](https://go.documentation.sas.com/doc/en/itopscdc/default/caltenants/p0emzq13c0zbhxn1hktsdlmig934.htm#p1ghvmezrb3cvxn1h7vg4uguqct6). | multi-tenancy |
| V4MT_TENANT_CAS_CUSTOMIZATION | Map of objects with all tenant CAS customization variables. See the format below. | | | false | | multi-tenancy |

### Tenant CAS Customization

Some of the tenant CAS customizations can be defined with the V4MT_TENANT_CAS_CUSTOMIZATION variable, which is a map of objects. The variable has the following format:

```bash
V4MT_TENANT_CAS_CUSTOMIZATION:
  <tenant-id1>:
    ...
  <tenant-id2>:
    ...
  ...
```
Below is the list of parameters each element can contain.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| memory | Amount of RAM to allocate to per CAS node | string | | false | Numeric value followed by the units, such as 32Gi for 32 gibibytes. In Kubernetes, the unit  is Gi. | multi-tenancy |
| cpus | Number of CPU cores to allocate per CAS node | string | | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores. | multi-tenancy |
| loadbalancer_enabled | Set up LoadBalancer to access CAS binary ports | bool | false | false | | multi-tenancy |
| loadbalancer_source_ranges | LoadBalancer source ranges specific to the tenant | list | false | false | | multi-tenancy |
| worker_count | The number of CAS worker nodes for tenants. Default is 0 (SMP) | int | 0 | false | | multi-tenancy |
| backup_controller_enabled | Enable backup CAS controller | bool | false | false | | multi-tenancy |

Example:

```bash
V4MT_TENANT_CAS_CUSTOMIZATION:
  acme:
    memory: 3Gi
    cpus: 300m
    loadbalancer_enabled: true
    loadbalancer_source_ranges: ['0.0.0.0/0']
    worker_count: 0
    backup_controller_enabled: false
  intech:
    memory: 2Gi
    cpus: 250m
    worker_count: 1
    backup_controller_enabled: true
```
