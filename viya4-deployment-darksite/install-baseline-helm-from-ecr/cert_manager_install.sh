#!/bin/bash

source 00_vars.sh

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p 'cert-manager helm chart version (do not include the proceeding "v"): ' CHART_VERSION

# output tmp.yaml
read -r -d '' TMP_YAML <<EOF
image:
     repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/quay.io/jetstack/cert-manager-controller
webhook:
     image:
          repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/quay.io/jetstack/cert-manager-webhook
cainjector:
     image:
          repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/quay.io/jetstack/cert-manager-cainjector
startupapicheck:
     image:
          repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/quay.io/jetstack/cert-manager-ctl
installCRDs: "true"
extraArgs:
- --enable-certificate-owner-ref=true
EOF
echo "${TMP_YAML}" > tmp.yaml

echo -e "Installing cert-manager...\n\n"

helm upgrade --cleanup-on-fail \
     --install cert-manager oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/cert-manager \
     --version=v$CHART_VERSION \
     --values tmp.yaml \
     --namespace cert-manager \
     --create-namespace

# cleanup
unset TMP_YAML
rm tmp.yaml