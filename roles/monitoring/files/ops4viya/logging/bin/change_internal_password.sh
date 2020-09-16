#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
source logging/bin/secrets-include.sh

USER_NAME=${1}

# if no user_name; ERROR and EXIT
if [ "$USER_NAME" == "" ]; then
  log_error "Required argument [USER_NAME] not provided."
  exit 1
else
  case $USER_NAME in
   admin)
     ;;
   logcollector)
     ;;
   kibanaserver)
     ;;
   metricgetter)
     ;;
   *)
     log_error "The user name [$USER_NAME] you provided is not one of the supported internal users; exiting"
     exit 2
  esac
fi

# generate UUID as password if one not provided
NEW_PASSWD="${2:-$(uuidgen)}"

log_debug USER_NAME: $USER_NAME
log_debug NEW_PASSWD: $NEW_PASSWD

kubectl -n $LOG_NS exec v4m-es-master-0 -it -- ./config/set_user_password.sh $USER_NAME $NEW_PASSWD

# Retrieve log file from security admin script
kubectl -n $LOG_NS cp v4m-es-master-0:config/set_user_password.log $TMP_DIR/set_user_password.log

if [ "$(tail -n1  $TMP_DIR/set_user_password.log)" == "Done with success" ]; then
  log_info "The set_user_password.log script appears to have run successfully on the pod; you can review its output below:"
  success=true
else
  log_error "There was a problem running the set_user_password.sh script on the pod; review the output below:"
  success=false
fi

# show output from set_user_password.sh script
sed 's/^/   | /' $TMP_DIR/set_user_password.log

if [ "$success" == "true" ]; then
  log_info "Successfully changed the password for user [$USER_NAME] on the Elasticsearch pod."
  log_info "Trying to store the updated credentials in a Kubernetes secret."

  kubectl -n $LOG_NS delete secret internal-user-$USER_NAME  --ignore-not-found
  create_user_secret internal-user-$USER_NAME $USER_NAME $NEW_PASSWD
  rc=$?
  if [ "$rc" != "0" ]; then
    log_error "IMPORTANT! A Kubernetes secret holding the password for $USER_NAME no longer exists."
    log_error "This WILL cause problems when the Elasticsearch pods restart."
    log_error "Try re-running this script again OR manually creating the secret using the command: "
    log_error "kubectl -n $LOG_NS create secret generic --from-literal=username=$username --from-literal=password=$password "
  fi
else
  log_error "Unable to update the password for user [$USER_NAME] on the Elasticsearch pod; original password remains in place."
  exit 99
fi
