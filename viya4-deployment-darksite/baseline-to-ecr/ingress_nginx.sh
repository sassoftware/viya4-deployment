#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

source 00_vars.sh

# determine chart version to use
V_CEILING=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.ingressVersions.k8sMinorVersionCeiling.value')
V_FLOOR=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.ingressVersions.k8sMinorVersionFloor.value')

if [ $K8S_minor_version -ge $V_FLOOR ]; then
    CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.ingressVersions.k8sMinorVersionFloor.api.chartVersion')
    echo "Helm chart version: $CHART_VERSION"
elif [ $K8S_minor_version -le $V_CEILING ]; then
    CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.ingressVersions.k8sMinorVersionCeiling.api.chartVersion')
    echo "Helm chart version: $CHART_VERSION"
else
    echo "Error with your minor version!  Exiting..."
    exit 1
fi

## Get helm chart info
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
CONTROLLER_REGISTRY=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.image.registry')
CONTROLLER_IMAGE=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.image.image')
CONTROLLER_TAG=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.image.tag')
WEBHOOKS_REGISTRY=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.admissionWebhooks.patch.image.registry')
WEBHOOKS_TAG=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.admissionWebhooks.patch.image.tag')
WEBHOOKS_IMAGE=$(helm show values ingress-nginx/ingress-nginx --version=$CHART_VERSION | yq '.controller.admissionWebhooks.patch.image.image')
echo "controller repo: $CONTROLLER_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG" && echo "webhook repo: $WEBHOOKS_REGISTRY/$WEBHOOKS_IMAGE:$WEBHOOKS_TAG"
echo "*********************"


## pull the image
$DOCKER_SUDO docker pull $CONTROLLER_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG
$DOCKER_SUDO docker pull $WEBHOOKS_REGISTRY/$WEBHOOKS_IMAGE:$WEBHOOKS_TAG


# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name ingress-nginx # this repo is used to store the helm chart
aws ecr create-repository --no-cli-pager --repository-name $CONTROLLER_IMAGE
aws ecr create-repository --no-cli-pager --repository-name $WEBHOOKS_IMAGE

# push the helm charts to the ECR repo
helm pull ingress-nginx/ingress-nginx --version=$CHART_VERSION
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push ingress-nginx-$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm ingress-nginx-$CHART_VERSION.tgz


# ## update local image tag appropriately
$DOCKER_SUDO docker tag $CONTROLLER_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$CONTROLLER_IMAGE:$CONTROLLER_TAG
$DOCKER_SUDO docker tag $WEBHOOKS_REGISTRY/$WEBHOOKS_IMAGE:$WEBHOOKS_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WEBHOOKS_IMAGE:$WEBHOOKS_TAG

# # ## auth local $DOCKER_SUDO docker to ecr
aws ecr get-login-password --region $AWS_REGION |  $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$CONTROLLER_IMAGE:$CONTROLLER_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WEBHOOKS_IMAGE:$WEBHOOKS_TAG
