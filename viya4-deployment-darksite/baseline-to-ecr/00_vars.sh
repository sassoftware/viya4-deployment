#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## set variables
AWS_ACCT_ID=
AWS_REGION=

K8S_minor_version=25 # K8s v1.22.X minor would be 22 ... K8s v1.21.X minor version would be 21.  This must match your deployment!
DEPLOYMENT_VERSION=main # main will pull latest release of viya4-deployment.  But this can be set to a specific version if needed, example: 5.2.0

DOCKER_SUDO= # put sudo here, if you require sudo docker commands... else leave blank
