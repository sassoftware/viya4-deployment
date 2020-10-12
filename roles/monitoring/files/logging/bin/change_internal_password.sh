#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
source logging/bin/secrets-include.sh
this_script=`basename "$0"`

function show_usage {
   log_info  ""
   log_info  "Usage: $this_script USERNAME [PASSWORD] "
   log_info  ""
   log_info  "Changes the password for one of the special internal user accounts used by other components of the monitoring system to communicate "
   log_info  "with Elasticsearch.  In addition, the script upates the internal cache (i.e. corresponding Kubernetes secret) with the new value."
   log_info  ""
   log_info  "     USERNAME - REQUIRED; the internal username for which the password is be changed; "
   log_info  "                MUST be one of: admin, kibanaserver, logcollector or metricgetter"
   log_info  ""
   log_info  "     PASSWORD - OPTIONAL; the new password.  If not provided, a 36-character UUID will be generated and used as the password"
   log_info  ""
   echo ""
}


USER_NAME=${1}

# if no user_name; ERROR and EXIT
if [ "$USER_NAME" == "" ]; then
  log_error "Required argument [USER_NAME] not provided."
  exit 1
else
  case "$USER_NAME" in
   admin)
     ;;
   logcollector)
     ;;
   kibanaserver)
     ;;
   metricgetter)
     ;;
   --help|-h)
     show_usage
     exit
     ;;
   *)
     log_error "The user name [$USER_NAME] you provided is not one of the supported internal users; exiting"
     show_usage
     exit 2
     ;;
  esac
fi

# generate UUID as password if one not provided
NEW_PASSWD="${2:-$(uuidgen)}"

log_debug USER_NAME: $USER_NAME
log_debug NEW_PASSWD: $NEW_PASSWD

#get current credentials from Kubernetes secret
ES_USER=$(kubectl -n $LOG_NS get secret internal-user-$USER_NAME -o=jsonpath="{.data.\username}" |base64 --decode)
ES_PASSWD=$(kubectl -n $LOG_NS get secret internal-user-$USER_NAME -o=jsonpath="{.data.password}" |base64 --decode)
log_debug "ES_USER: $ES_USER ES_PASSWD: $ES_PASSWD"

# set up temporary port forwarding to allow curl access
ES_PORT=$(kubectl -n $LOG_NS get service v4m-es-client-service -o=jsonpath='{.spec.ports[?(@.name=="http")].port}')

# temp file used to capture command output
tmpfile=$TMP_DIR/output.txt

# command is sent to run in background
kubectl -n $LOG_NS port-forward --address localhost svc/v4m-es-client-service :$ES_PORT > $tmpfile  &

# get PID to allow us to kill process later
pfPID=$!
log_debug "pfPID: $pfPID"

# pause to allow port-forwarding messages to appear
sleep 5s

# determine which port port-forwarding is using
pfRegex='Forwarding from .+:([0-9]+)'
myline=$(head -n1  $tmpfile)

if [[ $myline =~ $pfRegex ]]; then
   TEMP_PORT="${BASH_REMATCH[1]}";
   log_debug "TEMP_PORT=${TEMP_PORT}"
else
   set +e
   log_error "Unable to obtain or identify the temporary port used for port-forwarding; exiting script.";
   kill -9 $pfPID
   rm -f  $tmpfile
   exit 18
fi

# Attempt to change password using current user credentials
response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_opendistro/_security/api/account"   -H 'Content-Type: application/json' -d'{"current_password" : "'"$ES_PASSWD"'", "password" : "'"$NEW_PASSWD"'"}' --user "$ES_USER:$ES_PASSWD" --insecure)
if [[ $response == 4* ]]; then
   log_warn "The currently stored credentials for [$USER_NAME] do NOT appear to be up-to-date; unable to use them to change password.[$response]"

   if [ "$USER_NAME" != "admin" ]; then

      log_info "Will attempt to use admin credentials to change password for [$USER_NAME]"

      ES_ADMIN_USER=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.username}" |base64 --decode)
      ES_ADMIN_PASSWD=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.password}" |base64 --decode)

      # make sure hash utility is executable
      kubectl -n $LOG_NS exec v4m-es-master-0 --  chmod +x /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh
      # get hash of new password
      hashed_passwd=$(kubectl -n $LOG_NS exec v4m-es-master-0 --  /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p $NEW_PASSWD)
      rc=$?
      if [ "$rc" == "0" ]; then

         #try changing password using admin password
         response=$(curl -s -o /dev/null -w "%{http_code}"  -XPATCH "https://localhost:$TEMP_PORT/_opendistro/_security/api/internalusers/$ES_USER"   -H 'Content-Type: application/json' -d'[{"op" : "replace", "path" : "hash", "value" : "'"$hashed_passwd"'"}]'  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
         if [[ $response == 4* ]]; then
            log_error "The Kubernetes secret containing credentials for the [admin] user appears to be out-of-date.[$response]"
            echo ""
            log_error "+================================================================================================+"
            log_error "|                                *********** IMPORTANT NOTE ***********                          |"
            log_error "|                                                                                                |"
            log_error "| Cached credentials for [admin] user are not valid!                                             |"
            log_error "|                                                                                                |"
            log_error "| It is VERY IMPORTANT to ensure the credentials for the [admin] account and the corresponding   |"
            log_error "| Kubernetes secret [internal-user-admin] in the [$LOG_NS] namespace are ALWAYS synchronized.    |"
            log_error "|                                                                                                |"
            log_error "| You MUST re-run this script NOW with the updated password for the [admin] account to update    |"
            log_error "| the secret with the current password.                                                          |"
            log_error "|                                                                                                |"
            log_error "| You may then run this script again to update the password for the [$USER_NAME] account.      |"
            log_error "+================================================================================================+"
            echo ""
            success="false"
         elif [[ $response == 2* ]]; then
            log_info "Password for [$USER_NAME] has been changed in Elasticsearch.[$response]"
            success="true"
         else
            log_warn "Unable to change password for [$USER_NAME] using [admin] credentials. [$response]"
            success="false"
         fi
      else
         log_error "Unable to obtain a hash of the new password; password not changed. [rc: $rc]";
      fi
   else
      log_info "Attempting to change password for user [admin] using the admin certs rather than cached password"

      # make sure hash utility is executable
      kubectl -n $LOG_NS exec v4m-es-master-0 --  chmod +x /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh
      # get hash of new password
      hashed_passwd=$(kubectl -n $LOG_NS exec v4m-es-master-0 --  /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p $NEW_PASSWD)

      #obtain admin cert
      rm -f $TMP_DIR/tls.crt
      admin_tls_cert=$(kubectl -n logging get secrets es-admin-tls-secret -o "jsonpath={.data['tls\.crt']}")
      if [ -z "$admin_tls_cert" ]; then
         log_error "Unable to obtain admin certs from secret [es-admin-tls-secret] in the [$LOG_NS] namespace. Password for [$USER_NAME] has NOT been changed."
         success="false"
      else
         log_debug "File tls.crt obtained from Kubernetes secret"
         echo "$admin_tls_cert" |base64 --decode > $TMP_DIR/admin_tls.crt

         #obtain admin TLS key
         rm -f $TMP_DIR/tls.key
         admin_tls_key=$(kubectl -n logging get secrets es-admin-tls-secret -o "jsonpath={.data['tls\.key']}")
         if [ -z "$admin_tls_key" ]; then
            log_error "Unable to obtain admin cert key from secret [es-admin-tls-secret] in the [$LOG_NS] namespace. Password for [$USER_NAME] has NOT been changed."
            success="false"
         else
            log_debug "File tls.key obtained from Kubernetes secret"
            echo "$admin_tls_key" |base64 --decode > $TMP_DIR/admin_tls.key

            # Attempt to change password using admin certs
            response=$(curl -s -o /dev/null -w "%{http_code}" -XPATCH "https://localhost:$TEMP_PORT/_opendistro/_security/api/internalusers/$ES_USER"   -H 'Content-Type: application/json' -d'[{"op" : "replace", "path" : "hash", "value" : "'"$hashed_passwd"'"}]'  --cert $TMP_DIR/admin_tls.crt --key $TMP_DIR/admin_tls.key  --insecure)
            if [[ $response == 2* ]]; then
               log_info "Password for [$USER_NAME] has been changed in Elasticsearch.[$response]"
               success="true"
            else
               log_warn "Unable to change password for [$USER_NAME] using [admin] certificates.[$response]"
               success="false"
            fi
         fi
      fi
   fi
elif [[ $response == 2* ]]; then
   log_info "Password change response [$response]"
   success="true"
else
   log_error "An unexpected problem was encountered while attempting to update password for [$USER_NAME]; password not changed [$response]"
   success="false"
fi

# terminate port-forwarding and remove tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
rm -f $tmpfile
sleep 7s

if [ "$success" == "true" ]; then
  log_info "Successfully changed the password for [$USER_NAME] in Elasticsearch internal database."
  log_info "Trying to store the updated credentials in the corresponding Kubernetes secret [internal-user-$USER_NAME]."

  kubectl -n $LOG_NS delete secret internal-user-$USER_NAME  --ignore-not-found
  create_user_secret internal-user-$USER_NAME $USER_NAME $NEW_PASSWD
  rc=$?
  if [ "$rc" != "0" ]; then
    log_error "IMPORTANT! A Kubernetes secret holding the password for $USER_NAME no longer exists."
    log_error "This WILL cause problems when the Elasticsearch pods restart."
    log_error "Try re-running this script again OR manually creating the secret using the command: "
    log_error "kubectl -n $LOG_NS create secret generic --from-literal=username=$USER_NAME --from-literal=password=$NEW_PASSWD"
  else
    case $USER_NAME in
     admin)
       ;;
     logcollector)
       echo ""
       log_notice "+=============================================================================+"
       log_notice "|                        *********** IMPORTANT NOTE ***********               |"
       log_notice "|                                                                             |"
       log_notice "| After changing the password for the [logcollector] user, you should restart |"
       log_notice "| the Fluent Bit pods to ensure log collection is not interrupted.            |"
       log_notice "|                                                                             |"
       log_notice "| This can be done by submitting the following command:                       |"
       log_notice "+=============================================================================+"
       log_notice "|========== kubectl -n $LOG_NS delete pods -l 'app=fluent-bit' ===============|"
       log_notice "+=============================================================================+"
       echo ""
       ;;
     kibanaserver)
       echo ""
       log_notice "+======================================================================================+"
       log_notice "|                        *********** IMPORTANT NOTE ***********                        |"
       log_notice "|                                                                                      |"
       log_notice "| After changing the password for the [kibanaserver] user, you need to restart the     |"
       log_notice "| Kibana pod to ensure Kibana can still be accessed and used.                          |"
       log_notice "|                                                                                      |"
       log_notice "| This can be done by submitting the following command:                                |"
       log_notice "+======================================================================================+"
       log_notice "|==========   kubectl -n $LOG_NS delete pods -l 'app=v4m-es,role=kibana'  =============|"
       log_notice "+======================================================================================+"
       echo ""
       ;;
     metricgetter)
       echo ""
       log_notice "+======================================================================================+"
       log_notice "|                        *********** IMPORTANT NOTE ***********                        |"
       log_notice "|                                                                                      |"
       log_notice "| After changing the password for the [metricgetter] user, you should restart the      |"
       log_notice "| Elasticsearch Exporter pod to ensure Elasticsearch metrics continue to be collected. |"
       log_notice "|                                                                                      |"
       log_notice "| This can be done by submitting the following command:                                |"
       log_notice "+======================================================================================+"
       log_notice "|========== kubectl -n $LOG_NS delete pod -l 'app=elasticsearch-exporter' =============|"
       log_notice "+======================================================================================+"
       echo ""
       ;;
     *)
     log_error "The user name [$USER_NAME] you provided is not one of the supported internal users; exiting"
     exit 2
  esac

  fi
else
  log_error "Unable to update the password for user [$USER_NAME] on the Elasticsearch pod; original password remains in place."
  exit 99
fi
