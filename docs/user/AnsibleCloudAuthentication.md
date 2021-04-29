# Cloud Provider Authentication

The docker container includes cloud provider clis needed for interacting with the various cloud providers.

## GCP

When deploying to GCP we default to using [Google Cloud SQL proxy](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine). For security we set this up via workload identity configuration. This requires the following vars to be set:

### V4_CFG_POSTGRES_CONNECTION_NAME

Name of the sql cluster connection as listed in the gcp portal

### V4_CFG_POSTGRES_SERVICE_ACCOUNT

Name of service account in GCP that has the cloudsql.admin role. This account will be mapped to a kuberenetes service account thus granting the sql proxy access, via workload identity, to the sql server

### V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH 

Path to the `<V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME>` service account's JSON authentication file

### V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME 

Name of service account in GCP that has the iam.serviceAccountAdmin role. This account will be used to setting up the sql proxy's google service account mapping to the kubernetes service account

Example code ran by the tool:

```bash
NAMESPACE=dev
PROVIDER_ACCOUNT=my_gcp_project
V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME=cloud_service_account
V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH=$HOME/sa.json
V4_CFG_POSTGRES_SERVICE_ACCOUNT=sql_service_account

## Authenticate
gcloud auth activate-service-account \
  --key-file=${V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH} \
  ${V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME}

## Setup role binding
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --project ${PROVIDER_ACCOUNT} \
  --member "serviceAccount:${PROVIDER_ACCOUNT}.svc.id.goog[${NAMESPACE}/sql-proxy]" \
  ${V4_CFG_POSTGRES_SERVICE_ACCOUNT}@${PROVIDER_ACCOUNT}.iam.gserviceaccount.com
```


