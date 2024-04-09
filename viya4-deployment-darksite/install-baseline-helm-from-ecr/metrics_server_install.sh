#!/bin/bash

source 00_vars.sh

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p "metrics-server helm chart version: " CHART_VERSION

echo -e "Installing metrics-server...\n\n"

helm upgrade --cleanup-on-fail \
     --install metrics-server oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/metrics-server --version=$CHART_VERSION \
     --set image.registry=$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com \
     --set image.repository=metrics-server \
     --set apiService.create=true

# cleanup
unset TMP_YAML
rm tmp.yaml