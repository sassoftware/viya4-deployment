#!/bin/bash

## mirrormgr must be installed and in $PATH prior to running this script
## aws cli should be configured prior to running this script
## place your downloaded assets in the assets/ folder

### source variables from 00_vars.sh
source 00_vars.sh


# create repositories?
echo
read -p "Do you need to create the ECR repositories? (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # check if ECR repositories exist and create
    for repo in $(mirrormgr list target docker repos --deployment-data $CERTS --destination $NAMESPACE) ; do
        aws ecr create-repository --repository-name $repo --region $REGION
    done
fi


# proceed with mirroring images?
echo
read -p "Proceed with mirroring images?  this will take some time... (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # populate the repositories.. this will take some time!
    mirrormgr mirror registry -p ./sas_repos \
    --deployment-data $CERTS \
    --deployment-assets $ASSETS \
    --destination https://$AWS_ACCT_ID.dkr.ecr.$REGION.amazonaws.com/$NAMESPACE \
    --username 'AWS' \
    --password $(aws ecr get-login-password --region $REGION)
fi