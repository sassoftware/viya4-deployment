#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh

HELM_DEBUG="${HELM_DEBUG:-false}"

# Fluent Bit user customizations
FB_OPEN_USER_YAML="${FB_OPEN_USER_YAML:-$USER_DIR/logging/user-values-fluent-bit-open.yaml}"
if [ ! -f "$FB_OPEN_USER_YAML" ]; then
  log_debug "[$FB_OPEN_USER_YAML] not found. Using $TMP_DIR/empty.yaml"
  FB_OPEN_USER_YAML=$TMP_DIR/empty.yaml
fi

if [ -f "$USER_DIR/logging/fluent-bit_config.configmap_open.yaml" ]; then
   # use copy in USER_DIR
   FB_CONFIGMAP="$USER_DIR/logging/fluent-bit_config.configmap_open.yaml"
else
   # use copy in repo
   FB_CONFIGMAP="logging/fb/fluent-bit_config.configmap_open.yaml"
fi
log_info "Using FB ConfigMap:" $FB_CONFIGMAP

# Fluent Bit
# Create ConfigMap containing Fluent Bit configuration
kubectl -n $LOG_NS apply -f $FB_CONFIGMAP

# Create ConfigMap containing Viya-customized parsers (delete it first)
kubectl -n $LOG_NS delete configmap fb-viya-parsers --ignore-not-found
kubectl -n $LOG_NS create configmap fb-viya-parsers  --from-file=logging/fb/viya-parsers.conf

# Delete any existing Fluent Bit pods in the $LOG_NS namepace (otherwise Helm chart may assume an upgrade w/o reloading updated config
kubectl -n $LOG_NS delete pods -l "app=fluent-bit"

# Deploy Fluent Bit via Helm chart
if [ "$HELM_VER_MAJOR" == "3" ]; then
   helm2ReleaseCheck fb-$LOG_NS
   helm $helmDebug upgrade --install --namespace $LOG_NS fb --values logging/fb/fluent-bit_helm_values_open.yaml --values $FB_OPEN_USER_YAML  --set fullnameOverride=v4m-fb stable/fluent-bit
else
   helm3ReleaseCheck fb $LOG_NS
   helm $helmDebug upgrade --install fb-$LOG_NS --namespace $LOG_NS --values logging/fb/fluent-bit_helm_values_open.yaml   --values $FB_OPEN_USER_YAML --set fullnameOverride=v4m-fb stable/fluent-bit
fi
