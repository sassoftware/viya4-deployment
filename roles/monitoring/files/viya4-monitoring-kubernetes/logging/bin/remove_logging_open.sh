#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh

LOG_DELETE_PVCS_ON_REMOVE=${LOG_DELETE_PVCS_ON_REMOVE:-false}
LOG_DELETE_NAMESPACE_ON_REMOVE=${LOG_DELETE_NAMESPACE_ON_REMOVE:-false}

# Check for existing incompatible helm releases up front
helm2ReleaseCheck odfe-$LOG_NS
helm2ReleaseCheck es-exporter-$LOG_NS
helm3ReleaseCheck odfe $LOG_NS
helm3ReleaseCheck es-exporter $LOG_NS

log_info "Removing logging components [$(date)]"

logging/bin/remove_logging_fluentbit_open.sh

if [ "$HELM_VER_MAJOR" == "3" ]; then
    helm delete -n $LOG_NS es-exporter
    helm delete -n $LOG_NS odfe
else
    helm delete --purge es-exporter-$LOG_NS
    helm delete --purge odfe-$LOG_NS
fi

if [ "$LOG_DELETE_NAMESPACE_ON_REMOVE" == "true" ]; then
  log_info "Deleting the [$LOG_NS] namespace..."
  if kubectl delete namespace $LOG_NS; then
    log_info "[$LOG_NS] namespace and logging components successfully removed"
    exit 0
  else
    log_error "Unable to delete the [$LOG_NS] namespace"
    exit 1
  fi
fi

log_info "Removing eventrouter..."
kubectl delete --ignore-not-found -f logging/eventrouter.yaml

log_info "Removing components from the [$LOG_NS] namespace..."

if [ "$LOG_DELETE_PVCS_ON_REMOVE" == "true" ]; then
  log_info "Removing known logging PVCs..."
  kubectl delete pvc --ignore-not-found -n $LOG_NS -l app=v4m-es
fi

log_info "Waiting 60 sec for resources to terminate..."
sleep 60

log_info "Checking contents of the [$LOG_NS] namespace:"
crds=( all pvc )
empty="true"
for crd in "${crds[@]}"
do
	out=$(kubectl get -n $LOG_NS $crd 2>&1)
  if [[ "$out" =~ 'No resources found' ]]; then
    :
  else
    empty="false"
    log_warn "Found [$crd] resources in the [$LOG_NS] namespace:"
    echo "$out"
  fi
done
if [ "$empty" == "true" ]; then
  log_info "  The [$LOG_NS] namespace is empty and should be safe to delete."
else
  log_warn "  The [$LOG_NS] namespace is not empty."
  log_warn "  Examine the resources above before deleting the namespace."
fi
