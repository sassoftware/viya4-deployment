#!/bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This script is not intended to be run directly
# Assumes bin/common.sh has been sourced

if [ ! $(which kubectl) ]; then
  echo "kubectl not found on the current PATH"
  exit 1
fi

KUBE_CLIENT_VER=$(kubectl version --short | grep 'Client Version' | awk '{print $3}' 2>/dev/null)
KUBE_SERVER_VER=$(kubectl version --short | grep 'Server Version' | awk '{print $3}' 2>/dev/null)

if [[ $KUBE_CLIENT_VER =~ v1.1[4-9] ]]; then
  :
elif [[ $KUBE_CLIENT_VER =~ v1.2[0-9] ]]; then
  :
else 
  echo "Unsupported kubectl version: [$KUBE_CLIENT_VER]"
  exit 1
fi

# Minimuim version: 1.14
if [[ $KUBE_SERVER_VER =~ v1.1[4-9] ]]; then
  :
elif [[ $KUBE_SERVER_VER =~ v1.2[0-9] ]]; then
  :
else 
  echo "Unsupported Kubernetes server version: [$KUBE_SERVER_VER]"
  exit 1
fi

export KUBE_CLIENT_VER="$KUBE_CLIENT_VER"
export KUBE_SERVER_VER="$KUBE_SERVER_VER"
