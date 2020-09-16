#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#
# Deletes the following RBAC structure
#
#                                   /-- [ROLE: kibana_user]           |only link to backend role is deleted; kibana_user role NOT deleted
# [BACKEND_ROLE: {NS}_kibana_user]<-                                  |{NS}_kibana_user backend-role IS deleted
#                                   \-- [ROLE: search_index_{NS}]     |search_index_{NS} role IS deleted
#
#

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
this_script=`basename "$0"`

NAMESPACE=${1}

if [ -z "$NAMESPACE" ]; then
  log_error "Required argument NAMESPACE no specified"
  log_info  ""
  log_info  "Syntax: $this_script NAMESPACE"
  log_info  ""
  log_info  "        NAMESPACE - (Required) The Viya deployment/Kubernetes Namespace for which access controls should be deleted"

  exit 4
else
  log_notice "Deleting access controls for namespace [$NAMESPACE] [$(date)]"
fi


ROLENAME=search_index_$NAMESPACE
BACKENDROLE=${NAMESPACE}_kibana_users

log_debug "NAMESPACE: $NAMESPACE ROLENAME: $ROLENAME BACKENDROLE: $BACKENDROLE"


# get admin credentials
export ES_ADMIN_USER=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.username}" |base64 --decode)
export ES_ADMIN_PASSWD=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.password}" |base64 --decode)

#temp file to hold responses
tmpfile=$TMP_DIR/output.txt

# set up temporary port forwarding to allow curl access
ES_PORT=$(kubectl -n $LOG_NS get service v4m-es-client-service -o=jsonpath='{.spec.ports[?(@.name=="http")].port}')

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



# Delete role-mapping b/w Viya deployment-restricted role <==> backend-role
response=$(curl -s -o /dev/null -w "%{http_code}" -XDELETE "https://localhost:$TEMP_PORT/_opendistro/_security/api/rolesmapping/$ROLENAME"   --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
if [[ $response != 2* ]]; then
   log_error "There was an issue deleting the rolemapping between [$ROLENAME] and backend-role [$response]"
   kill -9 $pfPID
   exit 17
else
   log_info "Security rolemapping deleted between [$ROLENAME] and backend-role. [$response]"
fi


# Delete Viya deployment-restricted role
response=$(curl -s -o /dev/null -w "%{http_code}" -XDELETE "https://localhost:$TEMP_PORT/_opendistro/_security/api/roles/$ROLENAME"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
if [[ $response != 2* ]]; then
   log_error "There was an issue deleting the security role [$ROLENAME] [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Security role [$ROLENAME] deleted [$response]"
fi


# get existing rolemappings for kibana_user
response=$(curl -s -o $TMP_DIR/ku_rm.json -w "%{http_code}" -XGET "https://localhost:$TEMP_PORT/_opendistro/_security/api/rolesmapping/kibana_user"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

if [[ $response != 2* ]]; then
   log_error "There was an issue getting the existing rolemappings for [kibana_user]. [$response]"
   kill -9 $pfPID
   exit 17
else
   log_info "Existing rolemappings for [kibana_user] obtained. [$response]"
fi


# Extract and reconstruct backend_roles array from rolemapping json
newroles=$(grep -oP '"backend_roles":\[(.*)\],"h' $TMP_DIR/ku_rm.json | grep -oP '\[.*\]' | sed "s/\"$BACKENDROLE\"//; s/,,/,/; s/,]/]/" )
log_debug "Updated Back-end Roles: $newroles"

# Copy RBAC template
cp logging/es/odfe/rbac/kibana_user_backend_rolemapping_delete.json $TMP_DIR

#update json template file w/revised list of backend roles
sed -i "s/xxBACKENDROLESxx/$newroles/gI"     $TMP_DIR/kibana_user_backend_rolemapping_delete.json # BACKENDROLES

# Replace the rolemappings for the kibana_user with the revised list of backend roles
response=$(curl -s -o /dev/null -w "%{http_code}" -XPATCH "https://localhost:$TEMP_PORT/_opendistro/_security/api/rolesmapping/kibana_user"  -H 'Content-Type: application/json' -d @$TMP_DIR/kibana_user_backend_rolemapping_delete.json  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
if [[ $response != 2* ]]; then
   log_error "There was an issue updating the rolesmapping for [kibana_user] to remove link with backend-role [$BACKENDROLE]. [$response]"
   kill -9 $pfPID
   exit 17
else
   log_info "Security rolemapping deleted between [kibana_user] and backend-role [$BACKENDROLE]. [$response]"
fi


# terminate port-forwarding and remove tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
rm -f $tmpfile

#pause to allow port-forward kill message to appear
sleep 7s

log_notice "Access controls deleted [$(date)]"
echo ""
log_notice "==============================================================================================================="
log_notice "== You should delete any users whose only purpose was to access log messages from the [$NAMESPACE] namespace =="
log_notice "==============================================================================================================="

