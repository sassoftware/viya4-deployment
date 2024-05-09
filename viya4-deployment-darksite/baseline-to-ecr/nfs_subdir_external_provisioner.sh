#!/bin/bash

source 00_vars.sh

echo "**** nfs-subdir-external-provisioner ****"
CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.NFS_CLIENT_CHART_VERSION')
echo "Helm chart version: $CHART_VERSION"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
REPOSITORY=$(helm show values nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version=$CHART_VERSION | yq '.image.repository')
TAG=$(helm show values nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version=$CHART_VERSION | yq '.image.tag')
echo "Image repo: $REPOSITORY:$TAG"
echo "*****************************************"

## pull the image
$DOCKER_SUDO docker pull $REPOSITORY:$TAG

# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name nfs-subdir-external-provisioner

# push the helm chart to the ECR repo
helm pull nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version=$CHART_VERSION
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push nfs-subdir-external-provisioner-$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm nfs-subdir-external-provisioner-$CHART_VERSION.tgz

# ## update local image tag appropriately
$DOCKER_SUDO docker tag $REPOSITORY:$TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/nfs-subdir-external-provisioner:$TAG

# # ## auth local $DOCKER_SUDO docker to ecr
aws ecr get-login-password --region $AWS_REGION |  $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/nfs-subdir-external-provisioner:$TAG
