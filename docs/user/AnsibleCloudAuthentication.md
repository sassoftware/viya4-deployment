# Ansible Cloud Provider Authentication

The docker container contains cloud CLIs needed for interacting with the various clouds.

## Google Cloud

When using external postgres in Google Cloud, we default to using [Google Cloud SQL proxy](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine). For security the setup is via a workload identity configuration. This requires the following vars to be set:

### V4_CFG_POSTGRES_CONNECTION_NAME

Name of the SQL cluster connection, as listed in the Google Cloud console.

### V4_CFG_POSTGRES_SERVICE_ACCOUNT

Name of service account in Google Cloud that has the cloudsql.admin role. This account will be mapped to a Kubernetes service account, thus granting the SQL proxy access, via workload identity, to the SQL server.

### V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME 

Name of service account in Google Cloud that has the iam.serviceAccountAdmin role. This account will be used to setting up the sql proxy's Google service account mapping to the kubernetes service account

### V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH 

Path to the `<V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME>` service account's keys
