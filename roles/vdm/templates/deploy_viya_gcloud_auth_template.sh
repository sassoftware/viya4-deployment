#!/bin/bash

tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

dnf install google-cloud-cli -y
dnf install google-cloud-cli-gke-gcloud-auth-plugin -y


gcloud auth activate-service-account '{{ V4_CFG_CLOUD_SERVICE_ACCOUNT_NAME }}' --key-file=/config/v4_cfg_cloud_service_account_auth
kubectl get pods -n {{ NAMESPACE }}

{% for file in deployment_manifests.files %}
orchestration deploy --namespace {{ NAMESPACE }}  --sas-deployment-cr {{ file.path | replace(ORCHESTRATION_TOOLING_DIRECTORY, '/') }}
{% endfor %}