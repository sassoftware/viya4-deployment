#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh

set -e

# set env var with desired port
# default value returns random available port
export ES_PORT="${ES_PORT:-0}"

# set env var with service name
#export SVC=elasticsearch-master
export SVC=v4m-es-client-service

if [ "$ES_PORT" != "0" ]; then
   log_info "Making Elasticsearch instance [$SVC] in [$LOG_NS] namespace available on port [$ES_PORT]"
   echo
fi

# set env var to a node in cluster
export NODE_NAME=$(kubectl get nodes | awk 'NR==2 { print $1 }')

# Change port to a "NodePort"
kubectl -n "$LOG_NS" patch svc "$SVC" --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":'${ES_PORT}'}]'

# Determine which port was ultimately used
ACTUAL_ES_PORT=$(kubectl -n $LOG_NS get service v4m-es-client-service -o=jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Print URL to access Kibana
echo
log_notice "=========================================================================================================="
log_notice "== Access Elasticsearch using this URL: http://$NODE_NAME:$ACTUAL_ES_PORT/ =="
log_notice "=========================================================================================================="
