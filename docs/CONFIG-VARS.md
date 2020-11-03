# List of valid configuration variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

- [Cloud info](#cloud-info)
- [Misc](#misc)
- [Jump Server](#jump-server)
- [Storage](#storage)
  - [NFS](#nfs)
  - [Azure](#azure)
  - [AWS](#aws)
  - [GCP](#gcp)
- [Order](#order)
- [SAS API Access](#sas-api-access)
- [Container Registry Access](#container-registry-access)
- [Ingress](#ingress)
- [Monitoring and Logging](#monitoring-and-logging)
- [TLS](#tls)
  - [Cert-manager](#cert-manager)
- [Postgres](#postgres)
- [LDAP / Consul](#ldap--consul)
- [CAS](#cas)
- [CONNECT](#connect)

## Cloud info

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, vdm |
| CLUSTER_NAME | Name of the k8s cluster | string | | true | | baseline, vdm |
| NAMESPACE | K8s namespace in which to deploy | string | | true | | baseline, vdm, viya-monitoring |

## Misc

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy or stop at generating kustomize and manifest | bool | true | false | | vdm |
| LOADBALANCER_SOURCE_RANGES | IPs to allow to ingress | [string] | | true | When deploying in the cloud, be sure to add the cloud nat ip | baseline, vdm |
| BASE_DIR | Path to store persistent files | string | $HOME | false | | all |

## Jump Server

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
JUMP_SVR_HOST | ip/fqn to the jump host | string | | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |
JUMP_SVR_USER | ssh user to access the jump host | | string | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |
JUMP_SVR_PRIVATE_KEY | ssh user private key to access the jump host | | string | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |

## Storage

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_MANAGE_STORAGE | Whether to manage the storage class in k8s | bool | true | false | If you wish to manage the storage class yourself, set to false. | baseline, vdm |
| V4_CFG_STORAGECLASS | Storageclass name | string | "sas" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting storage class that supports ReadWriteMany | all |

### NFS

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_NFS_SVR_HOST | NFS ip/host | string | | false | | baseline, vdm |
| V4_CFG_NFS_SVR_PATH | NFS export path | string | /export | false | | baseline, vdm |
| V4_CFG_NFS_ASTORES_PATH | NFS path to astores dir | string | <V4_CFG_NFS_SVR_PATH>/\<NAMESPACE>/astores | false | | vdm |
| V4_CFG_NFS_BIN_PATH | NFS path to bin dir | string | <V4_CFG_NFS_SVR_PATH>/\<NAMESPACE>/bin | false | | vdm |
| V4_CFG_NFS_DATA_PATH | NFS path to data dir | string | <V4_CFG_NFS_SVR_PATH>/\<NAMESPACE>/data | false | | vdm |
| V4_CFG_NFS_HOMES_PATH | NFS path to homes dir | string | <V4_CFG_NFS_SVR_PATH>/\<NAMESPACE>/homes | false | | vdm |

### Azure

When setting V4_CFG_MANAGE_STORAGE to true, A new storage classes will be created: sas (Azure Netapp or NFS)

### AWS

When setting V4_CFG_MANAGE_STORAGE to true, the efs-provisioner will be deployed. A new storage classes will be created: sas (EFS or NFS)

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EFS_FSID | AWS EFS FSID | string | | false | Required for AWS deploys | baseline, vdm |
| V4_CFG_EFS_REGION | AWS EFS Region | string | | false | Required for AWS deploys | baseline, vdm |

### GCP

When setting V4_CFG_MANAGE_STORAGE to true, A new storage classes will be created: sas (Google Filestore or NFS)

## Order

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ORDER_NUMBER | SAS order number | string | | true | | vdm |
| V4_CFG_CADENCE_NAME | Cadence name | string | stable | false | [stable,fast,lts] | vdm |
| V4_CFG_CADENCE_VERSION | Cadence version | string | 2020.0.6 | true | | vdm |
| V4_CFG_DEPLOYMENT_ASSETS | Full path to pre-downloaded deployment assets | string | | false | Leave blank to download deployment assets | vdm |
| V4_CFG_LICENSE | Full path to pre-downloaded license file | string | | false| Leave blank to download license file | vdm |

## SAS API Access

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_API_KEY | SAS API Key| string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |
| V4_CFG_SAS_API_SECRET | SAS API Secret | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |

## Container Registry Access

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | true | | vdm |
| V4_CFG_CR_PASSWORD | Container registry password | string | | true | | vdm |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | | vdm |

## Ingress

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | Which ingress to deploy | string | | true | [ingress,istio] | baseline, vdm |
| V4_CFG_INGRESS_FQDN | FQDN to for viya installation | string | | true | | vdm |

## Monitoring and Logging

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_BASE_DOMAIN | Based domain in which subdomains for kibana, grafana, prometheus and alert manager will be created | string | | false | Require when deploying monitoring and logging | cluster-monitoring, cluster-logging |

## TLS

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_TLS_MODE | Which TLS mode to configure | string | full-stack | false | Valid values are full-stack, front-door and disabled. This also enables tls for monitoring/logging stack | all |
| V4_CFG_TLS_CERT | Path to ingress certificate file | string | | false | If specified, used instead of cert-manager issued certificates | vdm |
| V4_CFG_TLS_KEY | Path to ingress key file | string | | false | Required when V4_CFG_TLS_CERT is specified | vdm |
| V4_CFG_TLS_TRUSTED_CA_CERTS | Paths to additional PEM encoded trusted CA certificates files | list of string | | false | Required when V4_CFG_TLS_CERT is specified. Must include all the CAs in the trust chain for V4_CFG_TLS_CERT. Can be used with or without V4_CFG_TLS_CERT to specify any additionally trusted CAs  | vdm |

### Cert-manager

When setting V4_CFG_TLS_MODE to a value other than "disabled" and no V4_CFG_TLS_CERT is specified, cert-manager will be used to issue TLS certificates and the following variables can be set to modify cert-manager behavior:

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CM_CERTIFICATE_DURATION | Certificate time to expiry in hours | string | 17531h | false | vdm |
| V4_CFG_CM_CERTIFICATE_ADDITIONAL_SAN_DNS | A list of space separated, additional SAN DNS entries, specific to your ingress architecture, that you want added to certificates issued by the sas-viya-issuer.  For example, the aliases of an external load balancer | string | | false | vdm |
| V4_CFG_CM_CERTIFICATE_ADDITIONAL_SAN_IP | A list of space separated, additional SAN IP addresses, specific to your ingress architecture, that you want added to certificates issued by the sas-viya-issuer.  For example, the IP address of an external load balancer | string | | false | vdm |

## Postgres

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_TYPE | Postgres installation type | string | | true | [internal,external] | vdm |
| V4_CFG_POSTGRES_ADMIN_LOGIN | Postgres username | string | | true | Desired username for internal postgres or existing username for external postgres | vdm |
| V4_CFG_POSTGRES_PASSWORD | Postgres password | string | | true | Desired password for internal postgres or existing password for external postgres | vdm |
| V4_CFG_POSTGRES_FQDN | Postgres ip/fqdn | string | | false | Required for external postgres | vdm |
| V4_CFG_POSTGRES_PORT | Port that postgres is running on | string | 5432 | false | Required for external postgres | vdm |
| V4_CFG_POSTGRES_DATABASE | Postgres database name | string | "SharedServices" | false | Must be unique when using single Postgres cluster for multiple Viya deployments | vdm |

## LDAP / Consul

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EMBEDDED_LDAP_ENABLE | Deploy openldap in the namespace for authentication | bool | false | false | Default admin credentials are: user - viya_admin, password - Password123 | vdm |
| V4_CFG_CONSUL_ENABLE_LOADBALANCER | Expose conusl ui | bool | false | false | | vdm | Consul ui is exposed via service of type LoadBalancer on port 8500 that is accessible via the <LOADBALANCER_SOURCE_RANGES>.

## CAS

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_RAM | Amount of ram to allocate to per CAS node | string | | false | Numeric value followed by the units, such as 32Gi for 32 gigabytes. In Kubernetes, the units for gigabytes is Gi. Leave empty to enable auto-resource assignment | vdm |
| V4_CFG_CAS_CORES | Amount of cpu cores to allocate per CAS node | string | | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores. Leave empty to enable auto-resource assignment | vdm |
| V4_CFG_CAS_WORKER_COUNT | Number of CAS workers | int | 1 | false | Setting to more than one triggers MPP deployment | vdm |
| V4_CFG_CAS_ENABLE_BACKUP_CONTROLLER | Enable backup cas controller | bool | false | false | | vdm |
| V4_CFG_CAS_ENABLE_LOADBALANCER | Expose CAS binary ports | bool | false | false | Binary ports are exposed via service of type LoadBalancer that is accessible via the <LOADBALANCER_SOURCE_RANGES> | vdm |

## CONNECT

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONNECT_ENABLE_LOADBALANCER | Setup LB to access SAS/CONNECT | bool | false | false | | vdm |
| V4_CFG_CONNECT_FQDN | FQDN that will be assigned to access SAS/CONNECT | string | | false | Required when V4_CFG_TLS_MODE is not disabled and cert-manager is used to issue TLS certificates. This FQDN will be added to the SAN DNS list of the issued certificates. | vdm |