#!/bin/bash

source 00_vars.sh

# account for v6.3.0+ changes - autoscaler now supports k8s 1.25
DV=$(echo $DEPLOYMENT_VERSION | sed 's/\.//g')
if [ $DEPLOYMENT_VERSION == "main" ] && [ $K8S_minor_version -ge 25 ]; then
     CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.autoscalerVersions.PDBv1Support.api.chartVersion')
elif [ $DEPLOYMENT_VERSION == "main" ] && [ $K8S_minor_version -le 24 ]; then
     CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.autoscalerVersions.PDBv1beta1Support.api.chartVersion')
elif [ $DV -ge 630 ] && [ $K8S_minor_version -ge 25 ]; then
     CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.autoscalerVersions.PDBv1Support.api.chartVersion')
elif [ $DV -ge 630 ] && [ $K8S_minor_version -le 24 ]; then
     CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.autoscalerVersions.PDBv1beta1Support.api.chartVersion')
elif [ $DV -le 620 ] ; then
     CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.CLUSTER_AUTOSCALER_CHART_VERSION')
fi

## get chart version from viya4-deployment repo
echo "**** cluster-autoscaler ****"
echo "Helm chart version: $CHART_VERSION"
## Get helm chart info
helm repo add autoscaling https://kubernetes.github.io/autoscaler
helm repo update
IMG_REPO=$(helm show values autoscaling/cluster-autoscaler --version=$CHART_VERSION | yq '.image.repository')
TAG=$(helm show values autoscaling/cluster-autoscaler --version=$CHART_VERSION | yq '.image.tag')
echo "Image repo: $IMG_REPO" && echo "Image tag: $TAG"
echo "*********************"

## pull the image
$DOCKER_SUDO docker pull $IMG_REPO:$TAG


# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name cluster-autoscaler

# push the helm chart to the ECR repo
helm pull autoscaling/cluster-autoscaler --version=$CHART_VERSION
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push cluster-autoscaler-$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm cluster-autoscaler-$CHART_VERSION.tgz

# ## update local image tag appropriately
$DOCKER_SUDO docker tag $IMG_REPO:$TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/cluster-autoscaler:$TAG


# # ## auth local docker to ecr
aws ecr get-login-password --region $AWS_REGION | $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/cluster-autoscaler:$TAG
