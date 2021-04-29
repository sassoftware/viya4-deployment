# Ansible Cloud Provider Authentication

The docker container contains cloud clis needed for interacting with the various clouds.

## GCP

When using external postgres in GCP, we default to using [Google Cloud SQL proxy](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine). For security the setup is via a workload identity configuration. This requires the following vars to be set:

### V4_CFG_POSTGRES_CONNECTION_NAME

Name of the sql cluster connection as listed in the gcp portal

### V4_CFG_POSTGRES_SERVICE_ACCOUNT

Name of service account in GCP that has the cloudsql.admin role. This account will be mapped to a kuberenetes service account thus granting the sql proxy access, via workload identity, to the sql server

### V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME 

Name of service account in GCP that has the iam.serviceAccountAdmin role. This account will be used to setting up the sql proxy's google service account mapping to the kubernetes service account

### V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH 

Path to the `<V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME>` service account's keys
