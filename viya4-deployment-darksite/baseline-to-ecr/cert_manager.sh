#!/bin/bash

source 00_vars.sh


## get chart version from viya4-deployment repo
echo "**** cert-manager ****"
CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.CERT_MANAGER_CHART_VERSION')
echo "Helm chart version: $CHART_VERSION"
## Get helm chart info
helm repo add jetstack https://charts.jetstack.io/
helm repo update
IMG_CONTROLLER=$(helm show values jetstack/cert-manager --version=$CHART_VERSION | yq '.image.repository')
IMG_WEBHOOK=$(helm show values jetstack/cert-manager --version=$CHART_VERSION | yq '.webhook.image.repository')
IMG_CAINJECTOR=$(helm show values jetstack/cert-manager --version=$CHART_VERSION | yq '.cainjector.image.repository')
IMG_STARTUP=$(helm show values jetstack/cert-manager --version=$CHART_VERSION | yq '.startupapicheck.image.repository')
echo "controller repo: $IMG_CONTROLLER" && echo "webhook repo: $IMG_WEBHOOK" && echo "cainject repo: $IMG_CAINJECTOR" && echo "startupapicheck repo: $IMG_STARTUP"
echo "*********************"


## pull the images
$DOCKER_SUDO docker pull $IMG_CONTROLLER:v$CHART_VERSION
$DOCKER_SUDO docker pull $IMG_WEBHOOK:v$CHART_VERSION
$DOCKER_SUDO docker pull $IMG_CAINJECTOR:v$CHART_VERSION
$DOCKER_SUDO docker pull $IMG_STARTUP:v$CHART_VERSION


# create ECR repos
aws ecr create-repository --no-cli-pager --repository-name cert-manager # this repo is used to store the helm chart
aws ecr create-repository --no-cli-pager --repository-name $IMG_CONTROLLER
aws ecr create-repository --no-cli-pager --repository-name $IMG_WEBHOOK
aws ecr create-repository --no-cli-pager --repository-name $IMG_CAINJECTOR
aws ecr create-repository --no-cli-pager --repository-name $IMG_STARTUP

# push the helm charts to the ECR repo
helm pull jetstack/cert-manager --version=$CHART_VERSION
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push cert-manager-v$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm cert-manager-v$CHART_VERSION.tgz

# ## update local images tags appropriately
$DOCKER_SUDO docker tag $IMG_CONTROLLER:v$CHART_VERSION $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_CONTROLLER:v$CHART_VERSION
$DOCKER_SUDO docker tag $IMG_WEBHOOK:v$CHART_VERSION $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_WEBHOOK:v$CHART_VERSION
$DOCKER_SUDO docker tag $IMG_CAINJECTOR:v$CHART_VERSION $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_CAINJECTOR:v$CHART_VERSION
$DOCKER_SUDO docker tag $IMG_STARTUP:v$CHART_VERSION $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_STARTUP:v$CHART_VERSION

# # ## auth local $DOCKER_SUDO docker to ecr
aws ecr get-login-password --region $AWS_REGION |  $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local images to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_CONTROLLER:v$CHART_VERSION
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_WEBHOOK:v$CHART_VERSION
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_CAINJECTOR:v$CHART_VERSION
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_STARTUP:v$CHART_VERSION
