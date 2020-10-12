#!/bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source monitoring/bin/common.sh

set -e

DASH_NS="${DASH_NS:-$MON_NS}"

WELCOME_DASH="${WELCOME_DASH:-true}"
KUBE_DASH="${KUBE_DASH:-true}"
VIYA_DASH="${VIYA_DASH:-true}"
PGMONITOR_DASH="${PGMONITOR_DASH:-$VIYA_DASH}"
RABBITMQ_DASH="${RABBITMQ_DASH:-$VIYA_DASH}"
LOGGING_DASH="${LOGGING_DASH:-true}"
ISTIO_DASH="${ISTIO_DASH:-${ISTIO_ENABLED:-false}}"
TEST_DASH="${TEST_DASH:-false}"

DASH_BASE="${DASH_BASE:-monitoring/dashboards}"

# The kubectl --dry-run command changed as of v1.18
if [[ $KUBE_CLIENT_VER =~ v1.1[4-7] ]]; then
  dryRun="--dry-run"
elif [[ $KUBE_CLIENT_VER =~ v1.1[8-9] ]]; then
  dryRun="--dry-run=client"
elif [[ $KUBE_CLIENT_VER =~ v1.[2-9] ]]; then
  dryRun="--dry-run=client"
else 
  log_error "Unsupported kubectl version: [$KUBE_CLIENT_VER]"
  exit 1
fi

function deploy_dashboards {
   type=$1
   dir="$DASH_BASE/$type"
   
   log_message "--------------------------------"
   for f in $dir/*.json; do
     name=$(basename $f .json)
     kubectl create cm -n $DASH_NS $name $dryRun --from-file $f -o yaml | kubectl apply -f -
     kubectl label cm -n $DASH_NS $name --overwrite grafana_dashboard=1 sas.com/monitoring-base=kube-viya-monitoring sas.com/dashboardType=$type
   done
   log_message "--------------------------------"
}

log_info "Deploying SAS dashboards to the [$DASH_NS] namespace..."
log_message "--------------------------------"
if [ "$WELCOME_DASH" == "true" ]; then
  log_info "Deploying welcome dashboards..."
  deploy_dashboards "welcome"
fi

if [ "$KUBE_DASH" == "true" ]; then
  log_info "Deploying Kubernetes cluster dashboards..."
  deploy_dashboards "kube"
fi

if [ "$ISTIO_DASH" == "true" ]; then
  log_info "Deploying Istio dashboards..."
  deploy_dashboards "istio"
fi

if [ "$LOGGING_DASH" == "true" ]; then
  log_info "Deploying Logging dashboards..."
  deploy_dashboards "logging"
fi

if [ "$VIYA_DASH" == "true" ]; then
  log_info "Deploying SAS Viya dashboards..."
  deploy_dashboards "viya"
fi

if [ "$PGMONITOR_DASH" == "true" ]; then
  log_info "Deploying Postgres dashboards..."  
  deploy_dashboards "pgmonitor"
fi

if [ "$RABBITMQ_DASH" == "true" ]; then
  log_info "Deploying RabbitMQ dashboards..."
  deploy_dashboards "rabbitmq"
fi

log_info "Deployed dashboards to the [$DASH_NS] namespace"
