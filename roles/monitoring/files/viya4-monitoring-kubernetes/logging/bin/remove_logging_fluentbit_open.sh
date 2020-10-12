#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh

helm2ReleaseCheck fb-$LOG_NS
helm3ReleaseCheck fb $LOG_NS

log_info "Removing Fluent Bit components from the [$LOG_NS] namespace [$(date)]"

if [ "$HELM_VER_MAJOR" == "3" ]; then
    helm delete -n $LOG_NS fb
else
    helm delete --purge fb-$LOG_NS
fi
