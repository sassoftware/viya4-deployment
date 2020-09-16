# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

[[_TOC_]]

## Cloud info
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] |
| PROVIDER_ACCOUNT | Cloud provider account name | string | | true | |
| CLUSTER_NAME | Name of the k8s cluster | string | | true | |
| NAMESPACE | K8s namespace in which to deploy | string | | true | |

## Misc
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy or stop at generating kustomize and manifest | bool | true | false | |
| LOADBALANCER_SOURCE_RANGES | IPs to allow to ingress | [string] | | true | When deploying in the cloud, be sure to add the cloud nat ip |
| BASE_DIR | Path to store persistent files | string | $HOME | false | |

## Jump Server
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
JUMP_SVR_HOST | ip/fqn to the jump host | string | true | Tool uses the jump server to interact with nfs storage. |
JUMP_SVR_USER | ssh user to access the jump host | string | true | Tool uses the jump server to interact with nfs storage. |
JUMP_SVR_PRIVATE_KEY | ssh user private key to access the jump host | | true | Tool uses the jump server to interact with nfs storage. |

## NFS / Storage
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_NFS_SVR_HOST | NFS ip/host | string | | false | Required for Azure deploys, GCP deploys, or custom nfs setups |
| V4_CFG_NFS_SVR_PATH | NFS export path | string | /export | false | Required for Azure deploys, GCP deploys, or custom nfs setups |
| V4_CFG_MANAGE_STORAGECLASS | Whether to manage the storage class in k8s | bool | false | false | If you wish to manage the storage class yourself, set to false. |
| V4_CFG_RWO_STORAGE_CLASS | ReadWriteOnce storage class name | string | "sas-rwo" | false | When V4_CFG_MANAGE_STORAGECLASS is false, set to the name of your preexisting storage class that supports ReadWriteOnce |
| V4_CFG_RWX_STORAGE_CLASS | ReadWriteMany storage class name | string | "sas-rwx" | false | When V4_CFG_MANAGE_STORAGECLASS is false, set to the name of your preexisting storage class that supports ReadWritMany |

### Azure
When setting V4_CFG_MANAGE_STORAGECLASS to true, two new storage classes will be created: sas-rwo (azure disk) and sas-rwx (azure file)

### AWS
When setting V4_CFG_MANAGE_STORAGECLASS to true, the efs-provisioner will be deployed. Two new storage classes will be created: sas-rwo (ebs) and sas-rwx (efs provided by the efs-provisioner)

| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EFS_FSID | AWS EFS FSID | string | | false | Required for AWS deploys |
| V4_CFG_EFS_REGION | AWS EFS Region | string | | false | Required for AWS deploys |

### GCP
When setting V4_CFG_MANAGE_STORAGECLASS to true, two new storage classes will be created: sas-rwo (gce-pd) and sas-rwx (gcp filestore provided by the nfs-client-provisioner)

## Order
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_ORDER_NUMBER | SAS order number | string | | true | |
| V4_CFG_SAS_CADENCE_NAME | Cadence name | string | fast | false | [stable,fast,lts] |
| V4_CFG_SAS_CADENCE_VERSION | Cadence version | string | (latest version) | false | |

## SAS API Access
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_CLIENT_ID | SAS API Client Id | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation |
| V4_CFG_SAS_CLIENT_SECRET | SAS API Client Secret | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation |

## Container Registry Access
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | true | |
| V4_CFG_CR_PASSWORD | Container registry password | string | | true | |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | |

## Ingress
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | Which ingress to deploy | string | | true | [ingress,istio] |
| V4_CFG_INGRESS_NAME | DNS name to VIYA install | string | | true | Desired FQDN to access viya |

## TLS
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONFIGURE_TLS | Install cert-manager | bool | false | false | This also enables tls form monitoring/logging stack |

## Postgres
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_TYPE | Postgres installation type | string | | true | [internal,external] |
| V4_CFG_POSTGRES_ADMIN_LOGIN | Postgres username | string | | true | Desired username for internal postgres or existing username for external postgres |
| V4_CFG_POSTGRES_PASSWORD | Postgres password | string | | true | Desired password for internal postgres or existing password for external postgres |
| V4_CFG_POSTGRES_FQDN | Postgres ip/fqdn | string | | false | Required for external postgres |
| V4_CFG_POSTGRES_DATABASE | Postgres database name | string | "SharedServices" | false | Must be unique when using single Postgres cluster for multiple Viya deployments |

## LDAP / Consul
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ENABLE_EMBEDDED_LDAP | Deploy openldap in the namespace for authentication | bool | false | false | |
| V4_CFG_ENABLE_CONSUL_UI | Setup LB to access consul ui | bool | false | false | |

## MPP
| Name | Description | Type | Default | Required | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_RAM_PER_NODE | Amount of ram to allocate to per CAS node | int | false | false | |
| V4_CFG_CAS_CORES_PER_NODE | Amount of cpu cores to allocate per CAS node | int | CAS node cpu count - 1 | false | |
| V4_CFG_CAS_WORKER_QTY | Number of CAS workers | int | # of CAS nodes - 1 | false | |
| V4_CFG_CAS_NODE_COUNT | Number of CAS nodes | int | # of CAS nodes | false | |