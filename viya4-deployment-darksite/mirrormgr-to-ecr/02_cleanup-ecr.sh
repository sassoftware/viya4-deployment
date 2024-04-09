#!/bin/bash

#  this script will help you quickly clean up viya related ECR repos

### source variables from 00_vars.sh
source 00_vars.sh

# get all the repos within the aws subscription
REPOS=$(aws ecr describe-repositories --region $REGION)

# delete the SAS Viya repos
read -p "Are you sure you'd like to delete all SAS Viya repos and images (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo $REPOS | jq -r --arg keyword $NAMESPACE '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
fi

# delete the 3rd party repos
read -p "Are you sure you'd like to delete all 3rd party SAS Viya related repos and images (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo $REPOS | jq -r --arg keyword cert-manager '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
    echo $REPOS | jq -r --arg keyword cluster-autoscaler '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
    echo $REPOS | jq -r --arg keyword ingress-nginx '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
    echo $REPOS | jq -r --arg keyword nfs-subdir-external-provisioner '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
    echo $REPOS | jq -r --arg keyword metrics-server '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
    echo $REPOS | jq -r --arg keyword openldap '.repositories[].repositoryName | select(. | contains($keyword))' | while read -r repo; do aws ecr delete-repository --repository-name $repo --force --no-cli-pager; done
fi
