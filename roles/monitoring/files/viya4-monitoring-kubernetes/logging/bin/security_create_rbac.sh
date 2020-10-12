#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#
# Creates the following RBAC structures
#
#                                   /-- [ROLE: kibana_user]       (allows access to Kibana)
# [BACKEND_ROLE: {NS}_kibana_user]<-
#                                   \-- [ROLE: search_index_{NS}] (allows access to log messages from {NS})
#
#
#
# READONLY ROLE
#
#                                        /- [ROLE: cluster_ro_perms]  (limits access to cluster to read-only)
#                                       /-- [ROLE: kibana_read_only]  (limits Kibana access to read-only)
#                                      /--- [ROLE: kibana_user]       (allows access to Kibana)
# [BACKEND_ROLE: {NS}_kibana_ro_user]<-
#                                      \--- [ROLE: search_index_{NS}] (allows access to log messages from {NS})
#

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
this_script=`basename "$0"`

function show_usage {
  log_info  "Usage: $this_script NAMESPACE"
  log_info  ""
  log_info  "Creates access control artifacts (e.g. roles, role-mappings, etc.) to limit access to the specified namespace."
  log_info  ""
  log_info  "        NAMESPACE - (Required) The Viya deployment/Kubernetes Namespace for which access controls should be created"
}

NAMESPACE=${1}
READONLY=${2:-false}


if [ "$READONLY" == "--add_read_only" ]; then
 READONLY="true"
 READONLY_FLAG="_ro"
elif [[ "$READONLY" =~ -H|--HELP|-h|--help ]]; then
 show_usage
 exit
elif [ "$READONLY" != "false" ]; then
 log_error "Unrecognized additional option(s) [$READONLY] provided."
 show_usage
 exit 2
fi

if [ -z "$NAMESPACE" ]; then
  log_error "Required argument NAMESPACE no specified"
  echo  ""
  show_usage
  exit 4
elif [[ "$NAMESPACE" =~ -H|--HELP|-h|--help ]]; then
 show_usage
 exit
else
  log_notice "Creating access controls for namespace [$NAMESPACE] [$(date)]"
fi

INDEX_PREFIX=viya_logs
ROLENAME=search_index_$NAMESPACE
BE_ROLENAME=${NAMESPACE}_kibana_users
if [ "$READONLY" == "true" ]; then
   RO_BE_ROLENAME=${NAMESPACE}_kibana_ro_users
else
   RO_BE_ROLENAME="null"
fi

log_debug "NAMESPACE: $NAMESPACE ROLENAME: $ROLENAME RO_BE_ROLENAME: $RO_BE_ROLENAME"

# Copy RBAC templates
cp logging/es/odfe/rbac $TMP_DIR -r

# Replace PLACEHOLDERS
sed -i "s/xxIDXPREFIXxx/$INDEX_PREFIX/gI"  $TMP_DIR/rbac/*.json                  # IDXPREFIX
sed -i "s/xxNAMESPACExx/$NAMESPACE/gI"     $TMP_DIR/rbac/*.json                  # NAMESPACE


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

function add_rolemapping {
 # adds $ROLENAME and $RO_BE_ROLENAME to the
 # rolemappings for $targetrole (create $targetrole if it does NOT exists)

 targetrole=$1
 berole=$2
 targetrole_template=${3:-null}
 log_debug "Parms passed to add_rolemapping function  targetrole=$targetrole  berole=$berole  targetrole_template=$targetrole_template"


 #Check if $targetrole role exists
 response=$(curl -s -o /dev/null -w "%{http_code}" -XGET "https://localhost:$TEMP_PORT/_opendistro/_security/api/roles/$targetrole"   --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

 if [[ $response == 404 && "$targetrole_template" != "null" ]]; then

     # targetrole does NOT exist and we know how to create it
     response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_opendistro/_security/api/roles/$targetrole"  -H 'Content-Type: application/json' -d @${targetrole_template}  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

     if [[ $response != 2* ]]; then
        log_error "There was an issue creating the security role [$targetrole] [$response]"
        log_debug "template contents: /n $(cat $targetrole_template)"
        kill -9 $pfPID
        exit 20
     else
        log_info "Security role [$targetrole] created [$response]"
     fi
 elif [[ $response == 2* ]]; then
   log_debug "Confirmed [$targetrole] exists."
 else
   log_error "There was a problem obtaining information for role [$targetrole]. [$response]"
   kill -9 $pfPID
   exit 20
 fi

 # get existing rolemappings for $targetrole
 response=$(curl -s -o $TMP_DIR/rolemapping.json -w "%{http_code}" -XGET "https://localhost:$TEMP_PORT/_opendistro/_security/api/rolesmapping/$targetrole"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

 if [[ $response == 404 ]]; then
    log_debug "Rolemappings for [$targetrole] do not exist; creating rolemappings. [$response]"

    json='{"backend_roles" : ["'"$berole"'"]}'
    verb=PUT

 elif [[ $response == 2* ]]; then
    log_debug "Existing rolemappings for [$targetrole] obtained. [$response]"
    log_debug "$(cat $TMP_DIR/rolemapping.json)"

    if [ "$(grep $berole  $TMP_DIR/rolemapping.json)" ]; then
       log_debug "A rolemapping between [$targetrole] and  back-end role [$berole] already appears to exist; leaving as-is."
       return
    else
       json='[{"op": "add","path": "/backend_roles/-","value":"'"$berole"'"}]'
       verb=PATCH
    fi

 else
     log_error "There was an issue getting the existing rolemappings for [$targetrole]. [$response]"
     kill -9 $pfPID
     exit 17
 fi

 log_debug "JSON data passed to curl [$verb]: $json"

 response=$(curl -s -o /dev/null -w "%{http_code}" -X${verb} "https://localhost:$TEMP_PORT/_opendistro/_security/api/rolesmapping/$targetrole"  -H 'Content-Type: application/json' -d "$json" --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
 if [[ $response != 2* ]]; then
    log_error "There was an issue creating the rolemapping between [$targetrole] and backend-role(s) ["$berole"]. [$response]"
    kill -9 $pfPID
    exit 22
 else
    log_info "Security rolemapping created between [$targetrole] and backend-role(s) ["$berole"]. [$response]"
 fi

}

#index user
add_rolemapping $ROLENAME $BE_ROLENAME $TMP_DIR/rbac/index_role.json

#kibana_user
add_rolemapping kibana_user $BE_ROLENAME null

# Additional work needed for create deployment-restricted READ_ONLY Kibana role
if [ "$READONLY" == "true" ]; then

   #index user
   add_rolemapping $ROLENAME $RO_BE_ROLENAME $TMP_DIR/rbac/index_role.json

   #kibana_user
   add_rolemapping kibana_user $RO_BE_ROLENAME null

   #cluster_ro_perms
   add_rolemapping cluster_ro_perms $RO_BE_ROLENAME $TMP_DIR/rbac/cluster_ro_perms_role.json

   #kibana_read_only
   add_rolemapping kibana_read_only $RO_BE_ROLENAME null
fi

# terminate port-forwarding and remove tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
rm -f $tmpfile

#pause to allow port-forward kill message to appear
sleep 7s

log_notice "Access controls created [$(date)]"
echo ""
log_notice "============================================================================================================================"
log_notice "== Assign users the back-end role of [${BE_ROLENAME}] to grant access to log messages for [$NAMESPACE] namespace and Kibana =="
if [ "$READONLY" == "true" ]; then
   log_notice "== Assign users the back-end role of [${RO_BE_ROLENAME}] to grant access to log messages for [$NAMESPACE] namespace but limit Kibana access to READ-ONLY =="
fi
log_notice "============================================================================================================================"
