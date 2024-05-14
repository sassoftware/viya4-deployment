#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

source 00_vars.sh

echo "**** openldap ****"
IMAGE=$(curl -s https://raw.githubusercontent.com/sassoftware/viya4-deployment/$DEPLOYMENT_VERSION/roles/vdm/templates/resources/openldap.yaml | yq -N '.spec.template.spec.containers[0].image  | select(. != null)')
echo "Image: $IMAGE"
echo "******************"

## pull the image
$DOCKER_SUDO docker pull $IMAGE


# create ECR repo
aws ecr create-repository --no-cli-pager --repository-name osixia/openldap


# ## update local image tag appropriately
$DOCKER_SUDO docker tag $IMAGE $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE


# # ## auth local docker to ecr
aws ecr get-login-password --region $AWS_REGION |  docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # ## puch local image to ecr
$DOCKER_SUDO docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE
