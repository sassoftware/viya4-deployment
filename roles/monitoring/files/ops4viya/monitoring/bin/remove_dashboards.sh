#!/bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source monitoring/bin/common.sh

DASH_NS="${DASH_NS:-$MON_NS}"

log_info "Removing SAS dashboards from [$DASH_NS] namespace..."

kubectl delete --ignore-not-found cm -n $DASH_NS -l grafana_dashboard=1,sas.com/monitoring-base=kube-viya-monitoring,sas.com/dashboardType

log_info "SAS dashboards removed from the [$DASH_NS] namespace"
