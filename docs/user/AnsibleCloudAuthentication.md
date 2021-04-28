# Cloud Authentication

The docker container contains the carious cloud clis for interacting with the various clouds.

## GCP

When deploying to GCP and using Google Cloud SQL the tool can setup the service account and binding in order to deploy [cloud-sql-proxy](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine). For security we use a workload identity. In order to set the binding, we need a service account with IAM permissions. The following vars are required

| Name | Description |
| :--- | :--- |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME | Name of service account that matches the name inside the V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH file |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH | Path to Service Account JSON file |
| V4_CFG_POSTGRES_CONNECTION_NAME | Sql cluster connection name |
| V4_CFG_POSTGRES_SERVICE_ACCOUNT | Service account in GCP with cloudsql.admin role |
