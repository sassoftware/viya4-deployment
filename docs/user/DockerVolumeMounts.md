# Docker Volume Mapping

Ansible vars to docker volume mounts mappings. For full listing of config vars see [CONFIG-VARS.md](../CONFIG-VARS.md)

## Base

| Ansible Var | Docker Mount |
| :--- | ---: |
| BASE_DIR | `--volume <desired_path>:/data `|
| KUBECONFIG | `--volume <desired_path>:/config/kubeconfig `|
| V4_CFG_SITEDEFAULT | `--volume <desired_path>:/config/v4_cfg_sitedefault `|
| V4_CFG_SSSD | `--volume <desired_path>:/config/v4_cfg_sssd `|

## Jump Server

| Ansible Var | Docker Mount |
| :--- | ---: |
| JUMP_SVR_PRIVATE_KEY | `--volume <desired_path>:/config/jump_svr_private_key `|

## Order

| Ansible Var | Docker Mount |
| :--- | ---: |
| V4_CFG_DEPLOYMENT_ASSETS | `--volume <desired_path>:/config/v4_cfg_deployment_assets `|
| V4_CFG_LICENSE | `--volume <desired_path>:/config/v4_cfg_license `|
| V4_CFG_CERTS | `--volume <desired_path>:/config/v4_cfg_certs `|

## TLS

| Ansible Var | Docker Mount |
| :--- | ---: |
| V4_CFG_TLS_CERT | `--volume <desired_path>:/config/v4_cfg_tls_cert `|
| V4_CFG_TLS_KEY | `--volume <desired_path>:/config/v4_cfg_tls_key `|
| V4_CFG_TLS_TRUSTED_CA_CERTS | `--volume <desired_path>:/config/v4_cfg_tls_trusted_ca_certs `|

## Cloud Info

| Ansible Var | Docker Mount |
| :--- | ---: |
| V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH | `--volume <desired_path>:/config/v4_cfg_cloud_service_account_auth `|
