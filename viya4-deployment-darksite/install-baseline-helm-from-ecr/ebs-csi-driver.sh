#!/bin/bash

## installs ebs-csi-driver via helm

source 00_vars.sh 

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p "What is the aws-ebs-csi-driver helm chart version? " CHART_VERSION
read -p "What is the eks.amazonaws.com/role-arn for EBS_CSI_DRIVER? " ARN

read -r -d '' TMP_YAML <<EOF
image:
     repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver
sidecars:
     provisioner:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/csi-provisioner
     attacher:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/csi-attacher
     snapshotter:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/csi-snapshotter
     livenessProbe:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/livenessprobe
     resizer:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/csi-resizer
     nodeDriverRegistrar:
          image:
               repository: $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/k8s.gcr.io/sig-storage/csi-node-driver-registrar
controller:
     region: "${AWS_REGION}"
     serviceAccount:
          create: true
          name: ebs-csi-controller-sa
     annotations:
          "eks.amazonaws.com/role-arn": "${ARN}"
EOF
echo "${TMP_YAML}" > tmp.yaml

# helm install
echo -e "\nInstalling ingress-nginx...\n"
helm upgrade --cleanup-on-fail \
     --install aws-ebs-csi-driver oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/aws-ebs-csi-driver --version=$CHART_VERSION \
     --values tmp.yaml \
     --namespace kube-system 

# cleanup
unset TMP_YAML
rm tmp.yaml