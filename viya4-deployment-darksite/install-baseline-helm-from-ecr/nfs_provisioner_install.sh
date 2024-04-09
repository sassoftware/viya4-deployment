#!/bin/bash

source 00_vars.sh

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p "nfs-subdir-external-provisioner helm chart version: " CHART_VERSION
read -p "RWX filestore endpoint: " ENDPOINT
read -p "RWX filestore path (don't include ../pvs): " ENDPOINT_PATH

# output tmp.yaml
read -r -d '' TMP_YAML <<EOF
image:
     repository: ${AWS_ACCT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/nfs-subdir-external-provisioner
nfs:
     server: "${ENDPOINT}"
     path: "${ENDPOINT_PATH}/pvs"
     mountOptions: 
          - noatime
          - nodiratime
          - 'rsize=262144'
          - 'wsize=262144'
storageClass:
     archiveOnDelete: "false"
     name: sas
EOF
echo "${TMP_YAML}" > tmp.yaml

echo -e "Installing nfs-subdir-external-provisioner...\n\n"

helm upgrade --cleanup-on-fail \
     --install nfs-subdir-external-provisioner oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/nfs-subdir-external-provisioner \
     --version=$CHART_VERSION \
     --values tmp.yaml \
     --namespace nfs-client \
     --create-namespace

# cleanup
unset TMP_YAML
rm tmp.yaml