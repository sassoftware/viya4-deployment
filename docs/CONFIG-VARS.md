# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Cloud info
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, vdm |
| PROVIDER_ACCOUNT | Cloud provider account name | string | | true | | baseline, vdm |
| CLUSTER_NAME | Name of the k8s cluster | string | | true | | baseline, vdm |
| NAMESPACE | K8s namespace in which to deploy | string | | true | | baseline, vdm, viya-monitoring |

## Misc
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| DEPLOY | Whether to deploy or stop at generating kustomize and manifest | bool | true | false | | vdm |
| LOADBALANCER_SOURCE_RANGES | IPs to allow to ingress | [string] | | true | When deploying in the cloud, be sure to add the cloud nat ip | baseline, vdm |
| BASE_DIR | Path to store persistent files | string | $HOME | false | | all |

## Jump Server
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
JUMP_SVR_HOST | ip/fqn to the jump host | string | | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |
JUMP_SVR_USER | ssh user to access the jump host | | string | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |
JUMP_SVR_PRIVATE_KEY | ssh user private key to access the jump host | | string | true | Tool uses the jump server to interact with nfs storage. | baseline, vdm |

## NFS / Storage
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_NFS_SVR_HOST | NFS ip/host | string | | false | Required for Azure deploys, GCP deploys, or custom nfs setups | baseline, vdm |
| V4_CFG_NFS_SVR_PATH | NFS export path | string | /export | false | Required for Azure deploys, GCP deploys, or custom nfs setups | baseline, vdm |
| V4_CFG_MANAGE_STORAGECLASS | Whether to manage the storage class in k8s | bool | false | false | If you wish to manage the storage class yourself, set to false. | baseline, vdm |
| V4_CFG_RWO_STORAGE_CLASS | ReadWriteOnce storage class name | string | "sas-rwo" | false | When V4_CFG_MANAGE_STORAGECLASS is false, set to the name of your preexisting storage class that supports ReadWriteOnce | all |
| V4_CFG_RWX_STORAGE_CLASS | ReadWriteMany storage class name | string | "sas-rwx" | false | When V4_CFG_MANAGE_STORAGECLASS is false, set to the name of your preexisting storage class that supports ReadWritMany | all |

### Azure
When setting V4_CFG_MANAGE_STORAGECLASS to true, two new storage classes will be created: sas-rwo (azure disk) and sas-rwx (azure file)

### AWS
When setting V4_CFG_MANAGE_STORAGECLASS to true, the efs-provisioner will be deployed. Two new storage classes will be created: sas-rwo (ebs) and sas-rwx (efs provided by the efs-provisioner)

| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EFS_FSID | AWS EFS FSID | string | | false | Required for AWS deploys | baseline, vdm |
| V4_CFG_EFS_REGION | AWS EFS Region | string | | false | Required for AWS deploys | baseline, vdm |

### GCP
When setting V4_CFG_MANAGE_STORAGECLASS to true, two new storage classes will be created: sas-rwo (gce-pd) and sas-rwx (gcp filestore provided by the nfs-client-provisioner)

## Order
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_ORDER_NUMBER | SAS order number | string | | true | | vdm |
| V4_CFG_SAS_CADENCE_NAME | Cadence name | string | fast | false | [stable,fast,lts] | vdm |
| V4_CFG_SAS_CADENCE_VERSION | Cadence version | string | (latest version) | false | | vdm |

## SAS API Access
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_CLIENT_ID | SAS API Client Id | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |
| V4_CFG_SAS_CLIENT_SECRET | SAS API Client Secret | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |

## Container Registry Access
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CR_USER | Container registry username | string | | true | | vdm |
| V4_CFG_CR_PASSWORD | Container registry password | string | | true | | vdm |
| V4_CFG_CR_URL | Container registry server | string | https://cr.sas.com | false | | vdm |

## Ingress
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_INGRESS_TYPE | Which ingress to deploy | string | | true | [ingress,istio] | baseline, vdm |
| V4_CFG_INGRESS_NAME | DNS name to VIYA install | string | | true | Desired FQDN to access viya | vdm |

## Monitoring and Logging
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_BASE_DOMAIN | Based domain in which subdomains for kibana, grafana, prometheus and alert manager will be created | string | | false | Require when deploying monitoring and logging | cluster-monitoring, cluster-logging |

## TLS
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONFIGURE_TLS | Install cert-manager | bool | false | false | This also enables tls form monitoring/logging stack | all |

## Postgres
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_TYPE | Postgres installation type | string | | true | [internal,external] | vdm |
| V4_CFG_POSTGRES_ADMIN_LOGIN | Postgres username | string | | true | Desired username for internal postgres or existing username for external postgres | vdm |
| V4_CFG_POSTGRES_PASSWORD | Postgres password | string | | true | Desired password for internal postgres or existing password for external postgres | vdm |
| V4_CFG_POSTGRES_FQDN | Postgres ip/fqdn | string | | false | Required for external postgres | vdm |
| V4_CFG_POSTGRES_DATABASE | Postgres database name | string | "SharedServices" | false | Must be unique when using single Postgres cluster for multiple Viya deployments | vdm |

## LDAP / Consul
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ENABLE_EMBEDDED_LDAP | Deploy openldap in the namespace for authentication | bool | false | false | | vdm |
| V4_CFG_ENABLE_CONSUL_UI | Setup LB to access consul ui | bool | false | false | | vdm |

## MPP
| Name | Description | Type | Default | Required | Notes | Used by Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_RAM_PER_NODE | Amount of ram to allocate to per CAS node | int | false | false | | vdm |
| V4_CFG_CAS_CORES_PER_NODE | Amount of cpu cores to allocate per CAS node | int | CAS node cpu count - 1 | false | | vdm |
| V4_CFG_CAS_WORKER_QTY | Number of CAS workers | int | # of CAS nodes - 1 | false | | vdm |
| V4_CFG_CAS_NODE_COUNT | Number of CAS nodes | int | # of CAS nodes | false | | vdm |