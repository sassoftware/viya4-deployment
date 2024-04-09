#!/bin/bash

source 00_vars.sh

echo "**** metrics-server ****"
CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.METRICS_SERVER_CHART_VERSION')
echo "Helm chart version: $CHART_VERSION"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
REGISTRY=$(helm show values bitnami/metrics-server --version=$CHART_VERSION | yq '.image.registry')
TAG=$(helm show values bitnami/metrics-server --version=$CHART_VERSION | yq '.image.tag')
IMAGE=$(helm show values bitnami/metrics-server --version=$CHART_VERSION | yq '.image.repository')
echo "Image repo: $REGISTRY/$IMAGE:$TAG"
echo "*********************"

## pull the image
$DOCKER_SUDO docker pull $REGISTRY/$IMAGE:$TAG


# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name metrics-server

# push the helm chart to the ECR repo
helm pull bitnami/metrics-server --version=$CHART_VERSION
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push metrics-server-$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm metrics-server-$CHART_VERSION.tgz


# ## update local image tag appropriately
$DOCKER_SUDO docker tag $REGISTRY/$IMAGE:$TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/metrics-server:$TAG


# # ## auth local $DOCKER_SUDO docker to ecr
aws ecr get-login-password --region $AWS_REGION |  $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/metrics-server:$TAG