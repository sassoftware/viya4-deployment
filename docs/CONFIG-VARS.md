# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Cloud info
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| PROVIDER | Cloud provider | string | | true | [aws,azure,gcp,custom] | baseline, vdm |
| PROVIDER_ACCOUNT | Cloud provider account name | string | | true | | baseline, vdm |
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

## NFS / Storage
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_NFS_SVR_HOST | NFS ip/host | string | | false | Required for Azure deploys, GCP deploys, or custom nfs setups | baseline, vdm |
| V4_CFG_NFS_SVR_PATH | NFS export path | string | /export | false | Required for Azure deploys, GCP deploys, or custom nfs setups | baseline, vdm |
| V4_CFG_MANAGE_STORAGE | Whether to manage the storage class in k8s | bool | true | false | If you wish to manage the storage class yourself, set to false. | baseline, vdm |
| V4_CFG_RWO_STORAGE_CLASS | ReadWriteOnce storage class name | string | "sas-rwo" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting storage class that supports ReadWriteOnce | all |
| V4_CFG_RWX_STORAGE_CLASS | ReadWriteMany storage class name | string | "sas-rwx" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting storage class that supports ReadWritMany | all |

### Azure
When setting V4_CFG_MANAGE_STORAGE to true, two new storage classes will be created: sas-rwo (Azure disk) and sas-rwx (Azure File, Azure Netapp, or NFS)

### AWS
When setting V4_CFG_MANAGE_STORAGE to true, the efs-provisioner will be deployed. Two new storage classes will be created: sas-rwo (ebs) and sas-rwx (efs provided by the efs-provisioner)

| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_EFS_FSID | AWS EFS FSID | string | | false | Required for AWS deploys | baseline, vdm |
| V4_CFG_EFS_REGION | AWS EFS Region | string | | false | Required for AWS deploys | baseline, vdm |

### GCP
When setting V4_CFG_MANAGE_STORAGE to true, two new storage classes will be created: sas-rwo (gce-pd) and sas-rwx (gcp filestore provided by the nfs-client-provisioner)

## Order
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_ORDER_NUMBER | SAS order number | string | | true | | vdm |
| V4_CFG_SAS_CADENCE_NAME | Cadence name | string | fast | false | [stable,fast,lts] | vdm |
| V4_CFG_SAS_CADENCE_VERSION | Cadence version | string | (latest version) | false | | vdm |

## SAS API Access
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_SAS_CLIENT_ID | SAS API Client Id | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |
| V4_CFG_SAS_CLIENT_SECRET | SAS API Client Secret | string | | true | [Viya Orders CLI](https://github.com/sassoftware/viya4-orders-cli) for documentation | vdm |

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
| V4_CFG_INGRESS_NAME | DNS name to VIYA install | string | | true | Desired FQDN to access viya | vdm |

## Monitoring and Logging
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_BASE_DOMAIN | Based domain in which subdomains for kibana, grafana, prometheus and alert manager will be created | string | | false | Require when deploying monitoring and logging | cluster-monitoring, cluster-logging |

## TLS
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONFIGURE_TLS | Install cert-manager | bool | false | false | This also enables tls form monitoring/logging stack | all |

## Postgres
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_POSTGRES_TYPE | Postgres installation type | string | | true | [internal,external] | vdm |
| V4_CFG_POSTGRES_ADMIN_LOGIN | Postgres username | string | | true | Desired username for internal postgres or existing username for external postgres | vdm |
| V4_CFG_POSTGRES_PASSWORD | Postgres password | string | | true | Desired password for internal postgres or existing password for external postgres | vdm |
| V4_CFG_POSTGRES_FQDN | Postgres ip/fqdn | string | | false | Required for external postgres | vdm |
| V4_CFG_POSTGRES_DATABASE | Postgres database name | string | "SharedServices" | false | Must be unique when using single Postgres cluster for multiple Viya deployments | vdm |

## LDAP / Consul
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ENABLE_EMBEDDED_LDAP | Deploy openldap in the namespace for authentication | bool | false | false | Default admin credentials are: user - viya_admin, password - Password123 | vdm |
| V4_CFG_ENABLE_CONSUL_UI | Setup LB to access consul ui | bool | false | false | | vdm |

## CAS
| Name | Description | Type | Default | Required | Notes | Actions |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CAS_SERVER_TYPE <sub>1</sub> | CAS deployment type | string | smp | false | [smp,mpp] | vdm
| V4_CFG_CAS_RAM_PER_NODE <sub>2</sub>| Amount of ram to allocate to per CAS node | string | 90% of the available RAM - 500.5Mi  | false | Numeric value followed by the units, such as 32Gi for 32 gigabytes. In Kubernetes, the units for gigabytes is Gi. | vdm |
| V4_CFG_CAS_CORES_PER_NODE | Amount of cpu cores to allocate per CAS node | string | CAS node cpu count - 1 | false | Either a whole number, representing that number of cores, or a number followed by m, indicating that number of milli-cores.| vdm |
| V4_CFG_CAS_WORKER_QTY | Number of CAS workers | int | # of K8s nodes designated for CAS - 1 | false | Used when V4_CFG_CAS_SERVER_TYPE is set to mpp | vdm |


<sub> 1. CAS MPP setup includes the backup controller. This project strongly recommends the best practice of 1 node per CAS controller, backup  and worker pod. A CAS configuration with 3 CAS workers would require 5 nodes allocated with the CAS label and taint (CAS controller (1), CAS backup (1), CAS workers (3). </sub>

<sub> 2. If multiple CAS pods must share the same node, the V4_CFG_CAS_RAM_PER_NODE must be modified. </sub>