#!/bin/bash

source 00_vars.sh

## get chart version from viya4-deployment repo
echo -e "\n**** aws-ebs-csi-driver ****"
CHART_VERSION=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/baseline/defaults/main.yml | yq '.EBS_CSI_DRIVER_CHART_VERSION')
echo "Helm chart version: $CHART_VERSION"
## Get helm chart info
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
HELM_CHART=$(helm show all aws-ebs-csi-driver/aws-ebs-csi-driver --version=$CHART_VERSION)
# echo "$HELM_CHART"
IMG_REPO=$(echo "$HELM_CHART" | yq -N '.image.repository | select(. != null)')
IMG_TAG=$(echo "$HELM_CHART" | yq -N '.appVersion | select(. != null)')
PROVISIONER_REPO=$(echo "$HELM_CHART" | yq -N '.sidecars.provisioner.image.repository | select(. != null)')
PROVISIONER_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.provisioner.image.tag | select(. != null)')
ATTACHER_REPO=$(echo "$HELM_CHART" | yq -N '.sidecars.attacher.image.repository | select(. != null)')
ATTACHER_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.attacher.image.tag | select(. != null)')
SNAPSHOTTER_REPO=$(echo "$HELM_CHART"  | yq -N '.sidecars.snapshotter.image.repository | select(. != null)')
SNAPSHOTTER_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.snapshotter.image.tag | select(. != null)')
LIVENESS_REPO=$(echo "$HELM_CHART"  | yq -N '.sidecars.livenessProbe.image.repository | select(. != null)')
LIVENESS_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.livenessProbe.image.tag | select(. != null)')
RESIZER_REPO=$(echo "$HELM_CHART"  | yq -N '.sidecars.resizer.image.repository | select(. != null)')
RESIZER_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.resizer.image.tag | select(. != null)')
NODEREG_REPO=$(echo "$HELM_CHART"  | yq -N '.sidecars.nodeDriverRegistrar.image.repository | select(. != null)')
NODEREG_TAG=$(echo "$HELM_CHART"  | yq -N '.sidecars.nodeDriverRegistrar.image.tag | select(. != null)')
echo "Driver image repo: $IMG_REPO" && echo "Image tag: v$IMG_TAG"
echo "Provisioning image repo: $PROVISIONER_REPO" && echo "Image tag: $PROVISIONER_TAG"
echo "Attacher image repo: $ATTACHER_REPO" && echo "Image tag: $ATTACHER_TAG"
echo "Snapshotter image repo: $SNAPSHOTTER_REPO" && echo "Image tag: $SNAPSHOTTER_TAG"
echo "Liveness image repo: $LIVENESS_REPO" && echo "Image tag: $LIVENESS_TAG"
echo "Resizer image repo: $RESIZER_REPO" && echo "Image tag: $RESIZER_TAG"
echo "NodeDriverRegister image repo: $NODEREG_REP" && echo "Image tag: $NODEREG_TAG"
echo "*********************"

## pull the image
$DOCKER_SUDO docker pull $IMG_REPO:v$IMG_TAG
$DOCKER_SUDO docker pull $PROVISIONER_REPO:$PROVISIONER_TAG
$DOCKER_SUDO docker pull $ATTACHER_REPO:$ATTACHER_TAG
$DOCKER_SUDO docker pull $SNAPSHOTTER_REPO:$SNAPSHOTTER_TAG
$DOCKER_SUDO docker pull $LIVENESS_REPO:$LIVENESS_TAG
$DOCKER_SUDO docker pull $RESIZER_REPO:$RESIZER_TAG
$DOCKER_SUDO docker pull $NODEREG_REPO:$NODEREG_TAG

# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name aws-ebs-csi-driver # this is to house to helm chart
aws ecr create-repository --no-cli-pager --repository-name $IMG_REPO
aws ecr create-repository --no-cli-pager --repository-name $PROVISIONER_REPO
aws ecr create-repository --no-cli-pager --repository-name $ATTACHER_REPO
aws ecr create-repository --no-cli-pager --repository-name $SNAPSHOTTER_REPO
aws ecr create-repository --no-cli-pager --repository-name $LIVENESS_REPO
aws ecr create-repository --no-cli-pager --repository-name $RESIZER_REPO
aws ecr create-repository --no-cli-pager --repository-name $NODEREG_REPO

# push the helm chart to the ECR repo
helm pull aws-ebs-csi-driver/aws-ebs-csi-driver --version=$CHART_VERSION
aws ecr get-login-password \
    --no-cli-pager \
    --region $AWS_REGION | helm registry login \
    --username AWS \
    --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
helm push aws-ebs-csi-driver-$CHART_VERSION.tgz oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
rm aws-ebs-csi-driver-$CHART_VERSION.tgz

# update local image tag appropriately
$DOCKER_SUDO docker tag $IMG_REPO:v$IMG_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_REPO:v$IMG_TAG
$DOCKER_SUDO docker tag $PROVISIONER_REPO:$PROVISIONER_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROVISIONER_REPO:$PROVISIONER_TAG
$DOCKER_SUDO docker tag $ATTACHER_REPO:$ATTACHER_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ATTACHER_REPO:$ATTACHER_TAG
$DOCKER_SUDO docker tag $SNAPSHOTTER_REPO:$SNAPSHOTTER_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SNAPSHOTTER_REPO:$SNAPSHOTTER_TAG
$DOCKER_SUDO docker tag $LIVENESS_REPO:$LIVENESS_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$LIVENESS_REPO:$LIVENESS_TAG
$DOCKER_SUDO docker tag $RESIZER_REPO:$RESIZER_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$RESIZER_REPO:$RESIZER_TAG
$DOCKER_SUDO docker tag $NODEREG_REPO:$NODEREG_TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$NODEREG_REPO:$NODEREG_TAG

# auth local docker to ecr
aws ecr get-login-password --region $AWS_REGION | $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMG_REPO:v$IMG_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROVISIONER_REPO:$PROVISIONER_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ATTACHER_REPO:$ATTACHER_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SNAPSHOTTER_REPO:$SNAPSHOTTER_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$LIVENESS_REPO:$LIVENESS_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$RESIZER_REPO:$RESIZER_TAG
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$NODEREG_REPO:$NODEREG_TAG
