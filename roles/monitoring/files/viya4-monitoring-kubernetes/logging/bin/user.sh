#!/bin/bash


# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
this_script=`basename "$0"`

function show_usage {
  which_action=$1
  case "$which_action" in
    "CREATE")
       log_info  ""
       log_info  "Usage: $this_script CREATE [REQUIRED_PARAMETERS] [OPTIONS] "
       log_info  ""
       log_info  "Creates a user in the internal user database and grants the user permission to access log messages for the specified namespace"
       log_info  ""
       log_info  "     -ns, --namespace   NAMESPACE - (Required) The Viya deployment/Kubernetes Namespace to which this user should be granted access"
       log_info  "     -u,  --user        USERNAME  - (Optional) The username to be created (defaults to match NAMESPACE)"
       log_info  "     -p,  --password    PASSWORD  - (Optional) The password for the newly created account (defaults to match USERNAME)"
       echo ""
       ;;
    "DELETE")
       log_info  "Usage: $this_script DELETE [REQUIRED_PARAMETERS]"
       log_info  ""
       log_info  "Removes the specified user from the internal user database"
       log_info  ""
       log_info  "     -u,  --user        USERNAME  - (Required) The username to be deleted."
       ;;
    *)
       log_info  ""
       log_info  "Usage: $this_script ACTION [REQUIRED_PARAMETERS] [OPTIONS] "
       log_info  ""
       log_info  "Creates or deletes a user in the internal user database.  Newly created users are granted permission to access log messages for the specified namespace"
       log_info  ""
       log_info  "        ACTION - (Required) one of the following actions: [CREATE, DELETE]"
       log_info  ""
       log_info  "        Additional help information, including details of required and optional parameters, can be displayed by submitting the command: $this_script ACTION --help"
       echo ""
       ;;
  esac
}

POS_PARMS=""

while (( "$#" )); do
  case "$1" in
    -ro|--readonly)
      # READ_ONLY functionality not currently supported
      READONLY_FLAG="_ro"
      shift
      ;;
    -ns|--namespace)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        NAMESPACE=$2
        shift 2
      else
        log_error "Error: A value for parameter [Namespace] has not been provided." >&2
        show_usage
        exit 2
      fi
      ;;
    -u|--username)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        USERNAME=$2
        shift 2
      else
        log_error "Error: A value for parameter [Username] has not been provided." >&2
        show_usage
      exit 2
      fi
      ;;
    -p|--password)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PASSWORD=$2
        shift 2
      else
        log_error "Error: A value for parameter [Password] has not been provided." >&2
        show_usage
        exit 2
      fi
      ;;
    -h|--help)
      SHOW_USAGE=1
      shift
      ;;
    -*|--*=) # unsupported flags
      log_error "Error: Unsupported flag $1" >&2
      show_usage
      exit 2
      ;;
    *) # preserve positional arguments
      POS_PARMS="$POS_PARMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$POS_PARMS"

action=${1^^}
shift

log_debug "Action: $action"

if [ "$SHOW_USAGE" == "1" ]; then
   show_usage $action
   exit
fi

# No positional parameters (other than ACTION) are supported
if [ "$#" -ge 1 ]; then
    log_error "Unexpected additional arguments were found; exiting."
    show_usage
    exit 4
fi


log_debug "POS_PARMS: $POS_PARMS"

if [ -z "$USERNAME"  ] && [ -z "$NAMESPACE" ]; then
  log_error "Required parameter(s) NAMESPACE and/or USERNAME not specified"
  show_usage $action
  exit 4
elif [ -z "$USERNAME" ]; then
  USERNAME="$NAMESPACE"
fi

log_debug "NAMESPACE: $NAMESPACE USERNAME: $USERNAME"


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


# Check if user exists
response=$(curl -s -o /dev/null -w "%{http_code}" -XGET "https://localhost:$TEMP_PORT/_opendistro/_security/api/internalusers/$USERNAME"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
if [[ $response == 404 ]]; then
   USER_EXISTS=false
else
   USER_EXISTS=true
fi
log_debug "USER_EXISTS: $USER_EXISTS"

case "$action" in
   CREATE)
      if [ -z "$NAMESPACE" ]; then
         log_error "Required argument NAMESPACE no specified"
         echo ""
         show_usage CREATE
         kill -9 $pfPID
         exit 2
      fi
      log_info "Attempting to create user [$USERNAME] and grant them access to namespace [$NAMESPACE] [$(date)]"

      INDEX_PREFIX=viya_logs
      ROLENAME=search_index_$NAMESPACE

      #Check if role exists
      response=$(curl -s -o /dev/null -w "%{http_code}" -XGET "https://localhost:$TEMP_PORT/_opendistro/_security/api/roles/$ROLENAME"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

      if [[ $response != 2* ]]; then
         log_error "The expected access control role [$ROLENAME] does NOT exist; the role must be created before users can be linked to that role."
         kill -9 $pfPID
         exit 5
      fi

      PASSWORD=${PASSWORD:-$USERNAME}

      cp logging/es/odfe/rbac $TMP_DIR -r

      # Replace PLACEHOLDERS
      sed -i "s/xxIDXPREFI|--/$INDEX_PREFIX/gI"  $TMP_DIR/rbac/*.json                  # IDXPREFIX
      sed -i "s/xxNAMESPACExx/$NAMESPACE/gI"     $TMP_DIR/rbac/*.json                  # NAMESPACE
      sed -i "s/xxPASSWORDxx/$PASSWORD/gI"       $TMP_DIR/rbac/*.json                  # PASSWORD
      sed -i "s/xxCREATEDBYxx/$this_script/gI"   $TMP_DIR/rbac/*.json                  # CREATEDBY
      sed -i "s/xxDATETIMExx/$(date)/gI"         $TMP_DIR/rbac/*.json                  # DATE

      log_debug "Contents of user.json template file after substitutions: \n $(cat $TMP_DIR/rbac/user.json)"

      # Check if user exists
      if [[ "$USER_EXISTS" == "true" ]]; then
         log_error "There was an issue creating the user [$USERNAME]; user already exists. [$response]"
         kill -9 $pfPID
         exit 19
      else
         log_debug "User [$USERNAME] does not exist. [$response]"
      fi

      # Create user
      response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_opendistro/_security/api/internalusers/$USERNAME"  -H 'Content-Type: application/json' -d @$TMP_DIR/rbac/user${READONLY_FLAG}.json  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)

      if [[ $response != 2* ]]; then
         log_error "There was an issue creating the user [$USERNAME]. [$response]"
         kill -9 $pfPID
         exit 17
      else
      log_info "User [$USERNAME] created. [$response]"
      fi
      log_notice "User [$USERNAME] added to internal user database [$(date)]"
      ;;
   DELETE)
      if [ -z "$USERNAME" ]; then
         log_error "Required argument USERNAME not specified"
         echo ""
         show_usage DELETE
         kill -9 $pfPID
         exit 2
      fi

      log_info "Attempting to remove user [$USERNAME] from the internal user database [$(date)]"

      # Check if user exists
      if [[ "$USER_EXISTS" != "true" ]]; then
         log_error "There was an issue deleting the user [$USERNAME]; the user does NOT exists. [$response]"
         kill -9 $pfPID
         exit 20
      else
         log_debug "User [$USERNAME] exists. [$response]"
      fi

      # Delete user
      response=$(curl -s -o /dev/null -w "%{http_code}" -XDELETE "https://localhost:$TEMP_PORT/_opendistro/_security/api/internalusers/$USERNAME"  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
      if [[ $response != 2* ]]; then
         log_error "There was an issue deleting the user [$USERNAME]. [$response]"
         kill -9 $pfPID
         exit 17
      else
         log_info "User [$USERNAME] deleted. [$response]"
         log_notice "User [$USERNAME] removed from internal user database [$(date)]"
      fi
      ;;
   *)
      log_error "Invalid action specified"
      kill -9 $pfPID
      exit 3
   ;;
esac



# terminate port-forwarding and remove tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
