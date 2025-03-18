# List of Valid Configuration Variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

- [List of Valid Configuration Variables](#list-of-valid-configuration-variables)
  - [BASE](#base)
  - [Cloud](#cloud)
    - [Authentication](#authentication)
  - [Jump Server](#jump-server)
  - [Storage for AWS](#storage-for-aws)
  - [Storage for Azure](#storage-for-azure)
  - [Storage for Google Cloud](#storage-for-google-cloud)
  - [NFS Storage](#nfs-storage)
    - [RWX Filestore](#rwx-filestore)
    - [Azure](#azure)
    - [AWS](#aws)
    - [Google Cloud](#google-cloud)
  - [SAS Software Order](#sas-software-order)
  - [SAS API Access](#sas-api-access)
  - [Container Registry Access](#container-registry-access)
  - [Ingress](#ingress)
  - [Load Balancer](#load-balancer)
  - [TLS](#tls)
  - [PostgreSQL](#postgresql)
  - [CAS](#cas)
  - [CONNECT](#connect)
  - [Workload Orchestrator](#workload-orchestrator)
  - [Miscellaneous](#miscellaneous)
  - [Third-Party Tools](#third-party-tools)
    - [Cert-manager](#cert-manager)
    - [Cluster Autoscaler](#cluster-autoscaler)
    - [EBS CSI Driver](#ebs-csi-driver)
    - [Ingress-nginx](#ingress-nginx)
    - [Metrics Server](#metrics-server)
    - [NFS Client](#nfs-client)
    - [Postgres NFS Client](#postgres-nfs-client)

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
| V4_DEPLOYMENT_OPERATOR_SCOPE | Where the SAS Viya Platform Deployment Operator should watch for SASDeployments | string | "cluster" | false | [namespace, cluster] [Additional documentation](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n137b56hwogd7in1onzys95awxqe.htm#p16ayulwlsuw8vn10bkpsjtw1ldg) describing these options is available. | viya |
| V4_DEPLOYMENT_OPERATOR_NAMESPACE | Namespace where the SAS Viya Platform Deployment Operator should be installed  | string | "sasoperator" | false | Only applicable when V4_DEPLOYMENT_OPERATOR_SCOPE="cluster". | viya |
| V4_DEPLOYMENT_OPERATOR_CRB | Name of the ClusterRoleBinding resource that is needed by the SAS Viya Platform Deployment Operator | string | "sasoperator" | false | [Additional documentation](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n137b56hwogd7in1onzys95awxqe.htm#p1arr91os91cg5n1tsmuamj6h10g) describing the resource is available. | viya |

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
| NAMESPACE | Kubernetes namespace in which to deploy | string | | true | | baseline, viya |

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

### Storage for AWS

When `V4_CFG_MANAGE_STORAGE` is set to `true`, viya4-deployment uses the [EBS CSI driver](#ebs-csi-driver) to create two elastic block storage based storage classes with the default names of `io2-vol-mq` and `io2-vol-pg`. The volume type for both storage classes defaults to `io2`. For EKS clusters, RabbitMQ makes PVC requests to create block storage persistent volumes using the `io2-vol-mq` storage class while Crunchy Postgres makes PVC requests to create block storage persistent volumes using the `io2-vol-pg` storage class. Viya4-deployment also creates the `sas` storage class using the nfs-subdir-external-provisioner Helm chart. If a jump server is used, viya4-deployment uses that server to create the folders for the `astores`, `bin`, `data` and `homes` RWX Filestore NFS paths that are outlined below in the [RWX Filestore](#rwx-filestore) section.

### Storage for Azure

By default, viya4-deployment uses the [Azure managed disks CSI driver](#azure-managed-disk-csi-driver) to create two elastic block storage based storage classes with the default names of `managed-csi-premium-v2-mq` and `managed-csi-premium-v2-pg`. The disk SKU for both storage classes defaults to `PremiumV2_LRS`. For AKS clusters, RabbitMQ makes PVC requests to create block storage persistent volumes using the `managed-csi-premium-v2-mq` storage class while Crunchy Postgres makes PVC requests to create block storage persistent volumes using the `managed-csi-premium-v2-pg` storage class. To use a different StorageClass for RabbitMQ, set the `V4_CFG_RABBITMQ_STORAGECLASS` property to the name of the StorageClass to use. To use a different StorageClass for Crunchy Postgres, set the `V4_CFG_CRUNCHY_STORAGECLASS` property to the name of the StorageClass to use.

**NOTE**: The Azure managed disk CSI Driver can only be included at AKS cluster creation time. It is included in all AKS clusters by default, and any AKS clusters created with viya4-iac-azure will have the driver installed. If you did not use the viya4-iac-azure project to create your AKS cluster, ensure that you have enabled the Azure disk CSI driver prior to using this project or disable the creation of the StorageClasses.

viya4-deployment also creates the `sas` storage class using the nfs-subdir-external-provisioner Helm chart. If a jump server is used, viya4-deployment uses that server to create the folders for the `astores`, `bin`, `data` and `homes` RWX Filestore NFS paths that are outlined below in the [RWX Filestore](#rwx-filestore) section.

### Storage for Google Cloud
When `V4_CFG_MANAGE_STORAGE` is set to `true`, viya4-deployment creates the `sas` and `pg-storage` storage classes using the nfs-subdir-external-provisioner Helm chart. If a jump server is used, viya4-deployment uses that server to create the folders for the `astores`, `bin`, `data` and `homes` RWX Filestore NFS paths that are outlined below in the [RWX Filestore](#rwx-filestore) section.

### NFS Storage

When `V4_CFG_MANAGE_STORAGE` is set to `true`, viya4-deployment creates NFS-based storage classes using the nfs-subdir-external-provisioner Helm chart.

When `V4_CFG_MANAGE_STORAGE` is set to `false`, viya4-deployment does not create the `sas` or `pg-storage` storage classes for you. In addition, viya4-deployment does not create or manage the RWX Filestore NFS paths. Before you run the SAS Viya deployment, you must set the values for `V4_CFG_RWX_FILESTORE_DATA_PATH` and `V4_CFG_RWX_FILESTORE_HOMES_PATH` to specify existing NFS folder locations. The viya4-deployment user can create the required NFS folders from the jump server before starting the deployment. Recommended attribute settings for each folder are as follows:
- **filemode**: `0777`
- **group**: the equivalent of `nogroup` for your operating system
- **owner**: `nobody`

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_MANAGE_STORAGE | Whether viya4-deployment should manage the StorageClass | bool | true | false | Set to false if you want to manage the StorageClass yourself. | all |
| V4_CFG_STORAGECLASS | StorageClass name | string | "sas" | false | When V4_CFG_MANAGE_STORAGE is false, set to the name of your preexisting StorageClass that supports ReadWriteMany. | baseline, viya |

#### RWX Filestore

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_RWX_FILESTORE_ENDPOINT | NFS IP address or host name | string | | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_PATH | NFS export path | string | /export | false | | baseline, viya |
| V4_CFG_RWX_FILESTORE_DATA_PATH | NFS path to data directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/data | false | | viya |
| V4_CFG_RWX_FILESTORE_HOMES_PATH | NFS path to homes directory | string | <V4_CFG_RWX_FILESTORE_PATH>/\<NAMESPACE>/homes | false | | viya |

#### Azure

When V4_CFG_MANAGE_STORAGE is set to `true`, the `sas` storage class is created (Azure NetApp or NFS).

#### AWS

When V4_CFG_MANAGE_STORAGE is set to `true`, the efs-provisioner is deployed, and the `sas` storage class is created (EFS or NFS).

#### Google Cloud

When V4_CFG_MANAGE_STORAGE is set to `true`, the `sas` and `pg-storage` storage classes are created (Google Filestore or NFS).

## SAS Software Order

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_ORDER_NUMBER | SAS software order ID | string | | true | | viya |
| V4_CFG_CADENCE_NAME | Cadence name | string | lts | false | [stable,lts] | viya |
| V4_CFG_CADENCE_VERSION | Cadence version | string | "2022.09" | true | This value must be surrounded by quotation marks to accommodate the updated SAS Cadence Version format. If the value is not quoted the deployment will fail. | viya |
| V4_CFG_DEPLOYMENT_ASSETS | Path to pre-downloaded deployment assets | string | | false | Leave blank to download [deployment assets](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=itopscon&docsetTarget=n08bpieatgmfd8n192cnnbqc7m5c.htm#n1x7yoeafv23xan1gew0gfipt9e9) | viya |
| V4_CFG_LICENSE | Path to pre-downloaded license file | string | | false| Leave blank to download the [license file](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=itopscon&docsetTarget=n08bpieatgmfd8n192cnnbqc7m5c.htm#p1odbfo85cz4r5n1j2tzx9zz9sbi) | viya |
| V4_CFG_CERTS | Path to pre-downloaded certificates file | string | | false| Leave blank to download the [certificates file](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=itopscon&docsetTarget=n08bpieatgmfd8n192cnnbqc7m5c.htm#n0pj0ewyle0gfkn1psri3kw5ghha) | viya |

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

## Load Balancer

| Name | <div style="width:150px">Description</div> | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_AWS_LB_SUBNETS | The AWS subnets and by association the AWS availability zones to deploy the load balancing service to. This variable sets an ingress-nginx annotation which interacts with the [Cloud Controller Manager](https://kubernetes.io/docs/tasks/administer-cluster/developing-cloud-controller-manager/) to set the subnets used by the AWS load balancer. Specifying a subnet value or values for this variable takes precedence over the Subnet Discovery method described in [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html) that relies on the tags applied to AWS subnets documented in scenario 2 of this [table.](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/BYOnetwork.md#supported-scenarios-and-requirements-for-using-existing-network-resources) This variable can be set with [BYO network scenarios 0-3](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/BYOnetwork.md#supported-scenarios-and-requirements-for-using-existing-network-resources). | string | | false | The value is either a comma separated list of subnet IDs, or a comma separated list of subnet names. Does not affect the subnets used for load balancers enabled with  `V4_CFG_CAS_ENABLE_LOADBALANCER`, `V4_CFG_CONNECT_ENABLE_LOADBALANCER`, or `V4_CFG_CONSUL_ENABLE_LOADBALANCER`. | baseline |

## TLS

The SAS Viya platform supports two certificate generators: cert-manager and openssl.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_TLS_GENERATOR | Which SAS-provided tool to use for certificate generation | string | openssl | false | Supported values: [`cert-manager`,`openssl`]. If set to `cert-manager`, `cert-manager` will be installed during baselining. | baseline, viya |
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
Several SAS Viya platform offerings require a second internal Postgres instance referred to as SAS Common Data Store or CDS PostgreSQL. See details [here](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p0wkxxi9s38zbzn19ukjjaxsc0kl). The list of software offerings that include CDS PostgreSQL is located at [SAS Common Data Store Requirements (for SAS Planning and Retail Offerings)](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#n03wzanutmc6gon1val5fykas9aa) in System Requirements for the SAS Viya platform. To deploy and configure a CDS PostgreSQL instance in addition to the default internal platform Postgres instance, specify "cds-postgres" for your second Postgres instance as shown in the example below:

**Note**: Starting with 2024.06, the SharedServices database is not created automatically during the initial deployment of the SAS Viya platform. Instead, you must manually create it before you start the SAS Viya platform deployment.
Please refer to [this section](https://github.com/sassoftware/viya4-deployment/blob/main/docs/user/PostgreSQL.md##202406-sharedservices-database-updated-behavior
) in the PostgreSQL.md documentation



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
| ssl_enforcement_enabled | Require ssl connection to external postgres | bool | | false | Required for external postgres servers. Ignored on Google Cloud when using cloud sql | viya |
| connection_name | External postgres database connection name | string | | false | Required for using cloud-sql-proxy on Google Cloud. See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
| service_account | External service account for postgres connectivity | string | | false | Required for using cloud-sql-proxy on Google Cloud. See [ansible cloud authentication](user/AnsibleCloudAuthentication.md) | viya |
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
| V4_CFG_CAS_ENABLE_AUTO_RESTART | Include a transformer so that the CAS servers will automatically restart during version updates performed by the SAS Viya Deployment Operator. | bool | true | false | This variable will not be applicable if you are not using the SAS Viya Deployment Operator by setting `V4_DEPLOYMENT_OPERATOR_ENABLED` to "false". See the [SAS Viya Platform Operations documentation](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1mtzb2zsvv581n1gpmwds3urbon) for additional information. | viya |

## CONNECT

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CONNECT_ENABLE_LOADBALANCER | Set up LoadBalancer to access SAS/CONNECT | bool | false | false | | viya |
| V4_CFG_CONNECT_FQDN | FQDN that is assigned to access SAS/CONNECT | string | | false | Required when V4_CFG_TLS_MODE is not disabled and cert-manager is used to issue TLS certificates. This FQDN is added to the SAN DNS list of the issued certificates. | viya |

## Workload Orchestrator

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- |------------:| ---: | ---: | ---: | ---: | ---: |
| V4_WORKLOAD_ORCHESTRATOR_ENABLED | Enables the [SAS Workload Orchestrator](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1vo217m7ffso5n11vxwsyycw4tg) service and configures the required ClusterRole and ClusterRoleBinding used by the daemon. Setting this to false will disable SAS Workload Orchestrator service entirely | bool | true | false | This flag is only applicable for cadences 2023.08 and newer, this flag will perform no action on older cadences. | viya |

The SAS Workload Orchestrator Service is used to manage workload started on demand through the launcher service. As of cadence 2023.08 this feature is now deployed by default. The SAS Workload Orchestrator daemons require information about resources on the nodes that can be used to run jobs. In order to obtain accurate resource information, it requires a ClusterRole and a ClusterRoleBinding to the SAS Workload Orchestrator service account which will be automatically configured by this project if you set `V4_WORKLOAD_ORCHESTRATOR_ENABLED` to true. 

Additional documentation for the SAS Workload Orchestrator Service can be found here in the [SAS Viya Platform Operations documentation](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p1vo217m7ffso5n11vxwsyycw4tg). 

## Miscellaneous

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| V4_CFG_CLUSTER_NODE_POOL_MODE | The mode of cluster node pool to use | string | "standard" | false | [standard, minimal] | viya |
| V4_CFG_EMBEDDED_LDAP_ENABLE | Deploy OpenLDAP in the namespace for authentication | bool | false | false | [Openldap Config](../roles/vdm/templates/generators/openldap-bootstrap-config.yaml). If you do not set this value to true, you must set `V4_CFG_SITEDEFAULT` to point to a sitedefault file which contains values applicable for your authentication configuration. | viya |
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
| CERT_MANAGER_CHART_VERSION | cert-manager Helm chart version | string | 1.16.2 | false | | baseline |
| CERT_MANAGER_CONFIG | cert-manager Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |

Notes:
  - cert-manager will only be installed if `V4_CFG_TLS_GENERATOR` is set to "cert-manager"

### Cluster Autoscaler

Cluster-autoscaler is currently only used for AWS EKS clusters. Google GKE and Azure AKS already have autoscaling features enabled by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| CLUSTER_AUTOSCALER_ENABLED | Whether to deploy cluster-autoscaler | bool | true | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_URL | Cluster-autoscaler Helm chart URL | string | See [this document](https://github.com/kubernetes/autoscaler/tree/master/charts) for more information. | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_NAME| Cluster-autoscaler Helm chart name | string | cluster-autoscaler | false | | baseline |
| CLUSTER_AUTOSCALER_CHART_VERSION | Cluster-autoscaler Helm chart version | string | 9.36.0 | false | Version `9.36.0` is used for Kubernetes clusters whose version is >= 1.25. For Kubernetes clusters whose version is <= 1.24 please set this variable to avoid errors. See [Artifact Hub](https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler) to determine application version. | baseline |
| CLUSTER_AUTOSCALER_CONFIG | Cluster-autoscaler Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. | false | | baseline |
| CLUSTER_AUTOSCALER_ACCOUNT | Cluster autoscaler AWS role ARN | string | | false | Required to enable cluster-autoscaler on AWS | baseline |
| CLUSTER_AUTOSCALER_LOCATION |AWS region where Kubernetes cluster is running | string | us-east-1 | false | | baseline |

**Cluster Autoscaler Notes:**

If you used [viya4-iac-aws:5.6.0](https://github.com/sassoftware/viya4-iac-aws/releases) or newer to create your infrastructure, a cluster autoscaler account should have been created for you with a policy that is compatible with both our default versions for the `CLUSTER_AUTOSCALER_CHART_VERSION` variable. If you choose an alternative version ensure that your autoscaler account has a policy that matches the recommendation from the [kubernetes/autoscaler documentation](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#iam-policy). This note is only applicable for EKS clusters.

### EBS CSI Driver

The EBS CSI driver is only used for kubernetes v1.23 or later AWS EKS clusters.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| EBS_CSI_DRIVER_CHART_URL | aws ebs csi driver helm chart url | string | https://kubernetes-sigs.github.io/aws-ebs-csi-driver | false | | baseline |
| EBS_CSI_DRIVER_CHART_NAME| aws ebs csi driver helm chart name | string | aws-ebs-csi-driver | false | | baseline |
| EBS_CSI_DRIVER_CHART_VERSION | aws ebs csi driver helm chart version | string | 2.38.1 | false | | baseline |
| EBS_CSI_DRIVER_CONFIG | aws ebs csi driver helm values | string | see [here](../roles/baseline/defaults/main.yml) | false | | baseline |
| EBS_CSI_DRIVER_ACCOUNT | cluster autoscaler aws role arn | string | | false | Required to enable the aws ebs csi driver on AWS | baseline |
| EBS_CSI_DRIVER_LOCATION | aws region where kubernetes cluster resides | string | us-east-1 | false | | baseline |
|EBS_CSI_RABBITMQ_STORAGE_CLASS_NAME| The EBS CSI storage class name for RabbitMQ | string | io2-vol-mq | false | | baseline |
|EBS_CSI_RABBITMQ_STORAGE_CLASS_VOLUME_TYPE| The EBS CSI volume type to use for RabbitMQ persistent volumes| string | io2 | false | Supported values: [`io2`, `io1`, `gp3`]  | baseline |
|EBS_CSI_RABBITMQ_STORAGE_CLASS_IOPSPERGB | IOPs per GB parameter for the `EBS_CSI_RABBITMQ_STORAGE_CLASS_NAME` storage class|string|1250|false |Multiply this value by the volume size in GiB to obtain total IOPS per volume  | baseline |
|EBS_CSI_RABBITMQ_STORAGE_CLASS_THROUGHPUT| Maximum volume throughput in MiB/s for the `EBS_CSI_RABBITMQ_STORAGE_CLASS_NAME` storage class| string| 400 | false | The maximum value for io2, io1 and gp3 volume types is 1000.| baseline |
|EBS_CSI_CRUNCHY_STORAGE_CLASS_NAME| The EBS CSI storage class name for Crunchy Postgres use| string| io2-vol-pg | false | | baseline |
|EBS_CSI_CRUNCHY_STORAGE_CLASS_VOLUME_TYPE| The EBS CSI volume type to use for Crunchy Postgres persistent volumes | string | io2 | false | Supported values: [`io2`, `io1`, `gp3`] | baseline |
|EBS_CSI_CRUNCHY_STORAGE_CLASS_IOPSPERGB | IOPs per GB parameter for the `EBS_CSI_CRUNCHY_STORAGE_CLASS_NAME` storage class | string | 40 | false |Multiply this value by the volume size in GiB to obtain total IOPS per volume | baseline |
|EBS_CSI_CRUNCHY_STORAGE_CLASS_THROUGHPUT | Maximum volume throughput in MiB/s for the `EBS_CSI_CRUNCHY_STORAGE_CLASS_NAME` storage class | string| 400 | false | The maximum value for io2, io1 and gp3 volume types is 1000.| baseline |
|EBS_CSI_CRUNCHY_STORAGE_CLASS_RECLAIM_POLICY | The ReclaimPolicy for the `EBS_CSI_CRUNCHY_STORAGE_CLASS_NAME` storage class. | string | Delete | false | Supported values: [`Delete`, `Retain`] **Note**: If set to `Retain`, manual deletion of the Crunchy Persistent Volumes is required after deleting the PostgresCluster.| baseline |

### Azure managed disk CSI Driver

The Azure managed disk CSI Driver can only be included at AKS cluster creation time. It is included in all AKS clusters by default, and any AKS clusters created with viya4-iac-azure will have the driver installed. If you did not use the viya4-iac-azure project to create your AKS cluster, ensure that you have enabled the Azure disk CSI driver prior to using this project or disable the creation of the StorageClasses.

By default, two block storage StorageClasses are created using the driver, one for RabbitMQ and one for Crunchy Postgres. The defaults for these StorageClasses are listed below. 

**Note**: The StorageClasses created by viya4-deployment are intended for the Premium SSD v2 or Ultra Disk types. If you would like to use the Premium SSD v1 type or lower, disable creation of the StorageClasses in this project and use one of the default StorageClasses provided by the CSI driver.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
|CREATE_AZURE_RABBITMQ_STORAGE_CLASS| Whether to create an Azure files StorageClass for RabbitMQ | bool | true | false | | baseline |
|AZURE_RABBITMQ_STORAGE_CLASS_NAME| The StorageClass name for RabbitMQ | string | managed-csi-premium-v2-mq | false | | baseline |
|AZURE_RABBITMQ_STORAGE_CLASS_SKU_NAME| The disk type SKU name to use for RabbitMQ persistent volumes | string | PremiumV2_LRS | false | Supported values: [`PremiumV2_LRS`, `UltraSSD_LRS`]  | baseline |
|AZURE_RABBITMQ_STORAGE_CLASS_DISKIOPS | Disk total IOPS parameter for the `AZURE_RABBITMQ_STORAGE_CLASS_NAME` storage class|string|3000|false | Refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) for IOPS limits considerations | baseline |
|AZURE_RABBITMQ_STORAGE_CLASS_THROUGHPUT| Maximum volume throughput in MiB/s for the `AZURE_RABBITMQ_STORAGE_CLASS_NAME` storage class| string| 400 | false | Refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) for throughput limits considerations | baseline |
|CREATE_AZURE_CRUNCHY_STORAGE_CLASS| Whether to create an Azure files StorageClass for Crunchy Postgres | bool | true | false | | baseline |
|AZURE_CRUNCHY_STORAGE_CLASS_NAME| The StorageClass name for Crunchy Postgres | string| managed-csi-premium-v2-pg | false | | baseline |
|AZURE_CRUNCHY_STORAGE_CLASS_SKU_NAME| The disk type SKU name to use for Crunchy Postgres persistent volumes | string | PremiumV2_LRS | false | Supported values: [`PremiumV2_LRS`, `UltraSSD_LRS`] | baseline |
|AZURE_CRUNCHY_STORAGE_CLASS_DISKIOPS | Disk total IOPS parameter for the `AZURE_CRUNCHY_STORAGE_CLASS_NAME` storage class | string | 5000 | false | Refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) for IOPS limits considerations | baseline |
|AZURE_CRUNCHY_STORAGE_CLASS_THROUGHPUT | Maximum volume throughput in MiB/s for the `AZURE_CRUNCHY_STORAGE_CLASS_NAME` storage class | string| 400 | false | Refer to the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types) for throughput limits considerations | baseline |
|AZURE_CRUNCHY_STORAGE_CLASS_RECLAIM_POLICY | The ReclaimPolicy for the `AZURE_CRUNCHY_STORAGE_CLASS_NAME` storage class | string | Delete | false | Supported values: [`Delete`, `Retain`] **Note**: If set to `Retain`, manual deletion of the Crunchy Persistent Volumes is required after deleting the PostgresCluster. | baseline |

### Ingress-nginx

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| INGRESS_NGINX_NAMESPACE | NGINX Ingress Helm installation namespace | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_URL | NGINX Ingress Helm chart URL | string | See [this document](https://kubernetes.github.io/ingress-nginx) for more information. | false | | baseline |
| INGRESS_NGINX_CHART_NAME | NGINX Ingress Helm chart name | string | ingress-nginx | false | | baseline |
| INGRESS_NGINX_CHART_VERSION | NGINX Ingress Helm chart version | string | "" | false | If left as "" (empty string), version `4.12.0` is used for Kubernetes clusters whose version is >= 1.28.X, for Kubernetes clusters whose version is <= 1.27.X you must set this variable to avoid errors. See [Supported Versions table](https://github.com/kubernetes/ingress-nginx/?tab=readme-ov-file#supported-versions-table) for the supported versions list. | baseline |
| INGRESS_NGINX_CONFIG | NGINX Ingress Helm values | string | See [this file](../roles/baseline/defaults/main.yml) for more information. Altering this value will affect the cluster. | false | | baseline |

### Metrics Server

Kubernetes Metrics Server installation is currently only applicable for AWS EKS clusters. Google GKE and Azure AKS already have a metric server provided by default.

| Name | Description | Type | Default | Required | Notes | Tasks |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| METRICS_SERVER_ENABLED | Whether to deploy Metrics Server | bool | true | false | | baseline |
| METRICS_SERVER_CHART_URL | Metrics Server Helm chart url | string | Go [here](https://charts.bitnami.com/bitnami/) for more information. | false | If an existing Metrics Server is installed, these options are ignored. | baseline |
| METRICS_SERVER_CHART_NAME | Metrics Server Helm chart name | string | metrics-server | false | If an existing Metrics Server is installed, these options are ignored. | baseline |
| METRICS_SERVER_CHART_VERSION | Metrics Server Helm chart version | string | 6.6.5 | false | If an existing Metrics Server is installed, these options are ignored. See [Artifact Hub](https://artifacthub.io/packages/helm/bitnami/metrics-server) to determine application version.| baseline |
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
