#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

source 00_vars.sh

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p "cluster name: " cluster_name
read -p "autoscaler ARN: " autoscaler_arn
read -p "cluster-autoscaler helm chart version: " CHART_VERSION

# output tmp.yaml
read -r -d '' TMP_YAML <<EOF
image:
     repository: ${AWS_ACCT_ID}.dkr.ecr.{$AWS_REGION}.amazonaws.com/cluster-autoscaler
awsRegion: "${AWS_REGION}"
autoDiscovery:
     clusterName: "${cluster_name}"
rbac:
     serviceAccount:
          name: cluster-autoscaler
          annotations:
               "eks.amazonaws.com/role-arn": "${autoscaler_arn}"
               "eks.amazonaws.com/sts-regional-endpoints": “true”
extraEnv:
     AWS_STS_REGIONAL_ENDPOINTS: regional
extraArgs:
     aws-use-static-instance-list: true
EOF
echo "${TMP_YAML}" > tmp.yaml

# helm install
echo -e "Installing auto-scaler...\n\n"
helm upgrade --cleanup-on-fail \
     --install cluster-autoscaler oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/cluster-autoscaler \
     --version=$CHART_VERSION \
     --values tmp.yaml

# cleanup
unset TMP_YAML
rm tmp.yaml
