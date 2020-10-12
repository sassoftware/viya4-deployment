#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cd "$(dirname $BASH_SOURCE)/../.."
source logging/bin/common.sh
source logging/bin/secrets-include.sh

# Collect Kubernetes events as pseudo-log messages?
EVENTROUTER_ENABLE=${EVENTROUTER_ENABLE:-true}

# Use multi-purpose Elasticsearch nodes?
ES_MULTIPURPOSE_NODES=${ES_MULTIPURPOSE_NODES:-false}

# Require TLS into Kibana?
LOG_KB_TLS_ENABLE=${LOG_KB_TLS_ENABLE:-false}

source bin/tls-include.sh
verify_cert_manager

checkDefaultStorageClass

# enable debug on Helm via env var
export HELM_DEBUG="${HELM_DEBUG:-false}"

if [ "$HELM_DEBUG" == "true" ]; then
  helmDebug="--debug"
fi

# Check for existing OpenDistro helm release
existingODFE="false"
if [ "$HELM_VER_MAJOR" == "3" ]; then
  if [ helm status -n $LOG_NS odfe 1>/dev/null 2>&1 ]; then
    existingODFE="true"
  fi
else
  if [ helm status odfe-$LOG_NS 1>/dev/null 2>&1 ]; then
    existingODFE="true"
  fi
fi

# Elasticsearch user customizations
ES_OPEN_USER_YAML="${ES_OPEN_USER_YAML:-$USER_DIR/logging/user-values-elasticsearch-open.yaml}"
if [ ! -f "$ES_OPEN_USER_YAML" ]; then
  log_debug "[$ES_OPEN_USER_YAML] not found. Using $TMP_DIR/empty.yaml"
  ES_OPEN_USER_YAML=$TMP_DIR/empty.yaml
fi
ES_OPEN_EXPORTER_USER_YAML="${ES_OPEN_EXPORTER_USER_YAML:-$USER_DIR/logging/user-values-es-exporter.yaml}"
if [ ! -f "$ES_OPEN_EXPORTER_USER_YAML" ]; then
  log_debug "[$ES_OPEN_EXPORTER_USER_YAML] not found. Using $TMP_DIR/empty.yaml"
  ES_OPEN_EXPORTER_USER_YAML=$TMP_DIR/empty.yaml
fi
FLUENT_BIT_ENABLED=${FLUENT_BIT_ENABLED:-true}

# Kibana user customizations
# NOTE: There is not KIBANA_OPEN_USER_YAML equivalent because
# Kibana is deployed as part of the Elasticsearch Helm chart
# User values for Kibana should be included in the ES_OPEN_USER_YAML

# temp file used to capture command output
tmpfile=$TMP_DIR/output.txt
rm -f tmpfile

if [ "$(kubectl get ns $LOG_NS -o name 2>/dev/null)" == "" ]; then
  kubectl create ns $LOG_NS
fi

set -e

log_notice "Deploying logging components to the [$LOG_NS] namespace [$(date)]"

if [ "$EVENTROUTER_ENABLE" == "true" ]; then
  log_info "STEP 1: Deploying eventrouter..."
  kubectl apply -f logging/eventrouter.yaml
fi

# TLS REQUIRED
if [ "$TLS_ENABLE" == "true" ]; then
  # TLS-specific Helm chart values currently maintained in separate YAML file
  ES_OPEN_TLS_YAML=logging/es/odfe/es_helm_values_tls_open.yaml

  if [ "$LOG_KB_TLS_ENABLE" == "true" ]; then
     # Kibana TLS-specific Helm chart values currently maintained in separate YAML file
     KB_OPEN_TLS_YAML=logging/es/odfe/es_helm_values_kb_tls_open.yaml
     # w/TLS: use HTTPS in curl commands
     KB_CURL_PROTOCOL=https
     log_debug "TLS enabled for Kibana"
  else
     # point to an empty yaml file
     KB_OPEN_TLS_YAML=$TMP_DIR/empty.yaml
     # w/o TLS: use HTTP in curl commands
     KB_CURL_PROTOCOL=http
     log_debug "TLS not enabled for Kibana"
  fi

  apps=( es-transport es-rest es-admin kibana )
  create_tls_certs $LOG_NS logging ${apps[@]}
else
  # point to empty yaml file
  ES_OPEN_TLS_YAML=$TMP_DIR/empty.yaml

  # point to yaml file w/ hard-coded admin credentials (needed for demo certs)
  KB_OPEN_TLS_YAML=logging/es/odfe/es_helm_values_kb_notls_open.yaml

  # w/TLS: use HTTPS in curl commands
  KB_CURL_PROTOCOL=http
  log_debug "TLS not enabled for logging components"
fi

# FEATURE FLAG: configure Elasticsearch security configuration
ES_SECURITY_CONFIG_ENABLE=${ES_SECURITY_CONFIG_ENABLE:-true}

if [ "$ES_SECURITY_CONFIG_ENABLE" == "true" ]; then
  # Elasticsearch Passwords
  export ES_ADMIN_PASSWD=${ES_ADMIN_PASSWD:-admin}
  export ES_KIBANASERVER_PASSWD=${ES_KIBANASERVER_PASSWD:-$(uuidgen)}
  export ES_LOGCOLLECTOR_PASSWD=${ES_LOGCOLLECTOR_PASSWD:-$(uuidgen)}
  export ES_METRICGETTER_PASSWD=${ES_METRICGETTER_PASSWD:-$(uuidgen)}


  # Create secrets containing SecurityConfig files
  create_secret_from_file securityconfig/action_groups.yml security-action-groups
  create_secret_from_file securityconfig/config.yml security-config
  create_secret_from_file securityconfig/internal_users.yml security-internal-users
  create_secret_from_file securityconfig/roles.yml security-roles
  create_secret_from_file securityconfig/roles_mapping.yml security-roles-mapping

  # Create secrets containing internal user credentials
  create_user_secret internal-user-admin admin $ES_ADMIN_PASSWD
  create_user_secret internal-user-kibanaserver kibanaserver $ES_KIBANASERVER_PASSWD
  create_user_secret internal-user-logcollector logcollector $ES_LOGCOLLECTOR_PASSWD
  create_user_secret internal-user-metricgetter metricgetter $ES_METRICGETTER_PASSWD

  # Create ConfigMap for securityadmin script
  if [ -z "$(kubectl -n $LOG_NS get configmap run-securityadmin.sh -o name 2>/dev/null)" ]; then
    kubectl -n $LOG_NS create configmap run-securityadmin.sh --from-file logging/es/odfe/bin/run_securityadmin.sh
  else
    log_info "Using existing ConfigMap [run-securityadmin.sh]"
  fi

  # Need to retrieve these from secrets in case secrets pre-existed
  export ES_ADMIN_USER=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.username}" |base64 --decode)
  export ES_ADMIN_PASSWD=$(kubectl -n $LOG_NS get secret internal-user-admin -o=jsonpath="{.data.password}" |base64 --decode)
  export ES_METRICGETTER_USER=$(kubectl -n $LOG_NS get secret internal-user-metricgetter -o=jsonpath="{.data.username}" |base64 --decode)
  export ES_METRICGETTER_PASSWD=$(kubectl -n $LOG_NS get secret internal-user-metricgetter -o=jsonpath="{.data.password}" |base64 --decode)
else
  # hard-code admin credentials to preserve support (temporarily) for demo security
  create_user_secret internal-user-admin admin admin
  export ES_ADMIN_USER=admin
  export ES_ADMIN_PASSWD=admin
fi

# Elasticsearch
log_info "STEP 2: Deploying Elasticsearch"

odfe_tgz_file=opendistro-es-1.8.0.tgz

baseDir=$(pwd)
if [ ! -f "$TMP_DIR/$odfe_tgz_file" ]; then
   cd $TMP_DIR

   rm -rf $TMP_DIR/opendistro-build
   log_info "Cloning Open Distro for Elasticsearch repo"
   git clone https://github.com/opendistro-for-elasticsearch/opendistro-build

   # checkout specific commit
   cd opendistro-build
   git checkout 2c139044ee31a490b58ac6a306a5a5ef5ef21383

   # build package
   log_info "Packaging Helm Chart for Elasticsearch"

   # cd opendistro-build/helm/opendistro-es/
   cd helm/opendistro-es/
   helm package .

   # move .tgz file to $TMP_DIR
   mv $odfe_tgz_file $TMP_DIR/$odfe_tgz_file

   # return to working dir
   cd $baseDir

   # remove repo directories
   rm -rf $TMP_DIR/opendistro-build
fi

# Make Elasticsearch repo available to Helm
if [[ ! $(helm repo list 2>/dev/null) =~ stable[[:space:]] ]]; then
  log_info "Adding 'stable' helm repository"
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
else
  log_debug "'stable' helm repository already exists"
fi

log_info "Updating helm repositories..."
helm repo update

# Deploy Elasticsearch via Helm chart
if [ "$HELM_VER_MAJOR" == "3" ]; then
   helm2ReleaseCheck odfe-$LOG_NS
   helm $helmDebug upgrade --install odfe --namespace $LOG_NS  --values logging/es/odfe/es_helm_values_open.yaml  --values "$ES_OPEN_TLS_YAML" --values "$KB_OPEN_TLS_YAML" --values "$ES_OPEN_USER_YAML" --set fullnameOverride=v4m-es $TMP_DIR/$odfe_tgz_file
else
   helm3ReleaseCheck odfe $LOG_NS
   helm $helmDebug upgrade --install odfe-$LOG_NS --namespace $LOG_NS --values logging/es/odfe/es_helm_values_open.yaml --values "$ES_OPEN_TLS_YAML"  --values "$KB_OPEN_TLS_YAML"  --values "$ES_OPEN_USER_YAML" --set fullnameOverride=v4m-es $TMP_DIR/$odfe_tgz_file
fi

# switch to multi-purpose ES nodes (if enabled)
if [ "$ES_MULTIPURPOSE_NODES" == "true" ]; then

   sleep 10s
   log_debug "Configuring Elasticsearch to use multi-purpose nodes"

   # Reconfigure 'master' nodes to be 'multipupose' nodes (i.e. support master, data and client roles)
   log_debug "Patching statefulset [v4m-es-master]"
   kubectl -n $LOG_NS patch statefulset v4m-es-master --patch "$(cat logging/es/odfe/es_multipurpose_nodes_patch.yml)"

   # By default, there will be no single-purpose 'client' or 'data' nodes; but patching corresponding
   # K8s objects to ensure their use in case user chooses to configure additional single-purpose nodes
   log_debug "Patching deployment [v4m-es-client]"
   kubectl -n $LOG_NS patch deployment v4m-es-client --type=json --patch '[{"op": "add","path": "/metadata/labels/esdata","value": "true" }]'

   log_debug "Patching statefulset [v4m-es-data]"
   kubectl -n $LOG_NS patch statefulset v4m-es-data  --type=json --patch '[{"op": "add","path": "/spec/template/metadata/labels/esdata","value": "true" }]'

   # patching 'client' and 'data' _services_ to tie use new multipurpose labels for node selection
   log_debug "Patching  service [v4m-es-client-service]"
   kubectl -n $LOG_NS patch service v4m-es-client-service --type=json --patch '[{"op": "remove","path": "/spec/selector/role"},{"op": "add","path": "/spec/selector/esclient","value": "true" }]'

   log_debug "Patching  service [v4m-es-data-service]"
   kubectl -n $LOG_NS patch service v4m-es-data-svc --type=json --patch '[{"op": "remove","path": "/spec/selector/role"},{"op": "add","path": "/spec/selector/esdata","value": "true" }]'

fi

# wait for pod to come up
log_info "Waiting [90] seconds to allow Elasticsearch PVCs to matched with available PVs [$(date)]"
sleep 90s

# Confirm PVC are "bound" (matched) to PVs
for line in $(kubectl -n $LOG_NS get pvc -l 'role=master' -o=jsonpath="{range .items[*]}[{.metadata.name},{.status.phase}] {end}")
   do
      if [[ $line =~ \[(.*),(.*)\] ]] && [ ${BASH_REMATCH[2]}  != "Bound" ]
      then
         log_error "It appears at least one PVC associated with the [master] nodes has not been bound to a PV."
         log_error "The status of PVC [${BASH_REMATCH[1]}] is [${BASH_REMATCH[2]}]"
         log_error "After ensuring all claims shown as Pending on the following list can be satisfied; run the remove_logging.sh script and try again."
         ###kubectl -n $LOG_NS get pvc -l 'app=elasticsearch-master'
         kubectl -n $LOG_NS get pvc -l 'role=master'
         exit 12
      fi
   done
log_info "Elasticsearch PVCs have been bound to PVs"

# Need to wait 2-3 minutes for the elasticsearch to come up and running
log_info "Checking on status of Elasticsearch pod before configuring [$(date)]"
podready="FALSE"

for pause in 40 30 20 15 10 10 10 15 15 15 30 30 30 30
do
   if [[ "$( kubectl -n $LOG_NS get pod -l 'role=master' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')" == *"True"* ]]; then
      log_info "Pod is ready...continuing."
      podready="TRUE"
      break
   else
      log_info "Pod is not ready yet...sleeping for [$pause] more seconds before checking again."
      sleep ${pause}s
   fi
done

if [ "$podready" != "TRUE" ]; then
   log_error "At least one of Elasticsearch [master] pods has NOT reached [Ready] status in the expected time; exiting."
   log_error "Review pod's events and log to identify the issue and resolve it; run the remove_logging.sh script and try again."
   exit 14
fi

if [ "$ES_SECURITY_CONFIG_ENABLE" == "true" ]; then

  log_info "Waiting [2] minute to allow Elasticsearch to initialize [$(date)]"
  sleep 120s

  set +e

  # Run the security admin script on the pod
  # Add some logic to find ES release
  if [ "$existingODFE" == "false" ]; then
    kubectl -n $LOG_NS exec v4m-es-master-0 -it -- config/run_securityadmin.sh
    # Retrieve log file from security admin script
    kubectl -n $LOG_NS cp v4m-es-master-0:config/run_securityadmin.log $TMP_DIR/run_securityadmin.log
    if [ "$(tail -n1  $TMP_DIR/run_securityadmin.log)" == "Done with success" ]; then
      log_info "The run_securityadmin.log script appears to have run successfully; you can review its output below:"
    else
      log_warn "There may have been a problem with the run_securityadmin.log script; review the output below:"
    fi
    # show output from run_securityadmin.sh script
    sed 's/^/   | /' $TMP_DIR/run_securityadmin.log
  else
    log_info "Existing OpenDistro release found. Skipping Elasticsearh security initialization."
  fi

  # Need to wait for completion?
  log_info "Waiting [1] minute to allow Elasticsearch to complete initialization [$(date)]"
  sleep 60s

  set -e
else
  log_info "Waiting [4] minutes to allow Elasticsearch to initialize [$(date)]"
  sleep 240s
fi

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

# Create Index Management (I*M) Policy  objects
response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_opendistro/_ism/policies/viya_logs_idxmgmt_policy" -H 'Content-Type: application/json' -d @logging/es/odfe/es_viya_logs_idxmgmt_policy.json  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
# Seems to return policy definition back to SSH window...NOT "true"?
if [[ $response == 409 ]]; then
   log_info "Index management policies already exist in Elasticsearch. Skipping load." 
elif [[ $response != 2* ]]; then
   log_error "There was an issue loading index management policies into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Index management policies loaded into Elasticsearch [$response]"
fi

# Create Ingest Pipeline to "burst" incoming log messages to separate indexes based on namespace
response=$(curl  -s -o /dev/null -w "%{http_code}"  -XPUT "https://localhost:$TEMP_PORT/_ingest/pipeline/viyaburstns" -H 'Content-Type: application/json' -d @logging/es/es_create_ns_burst_pipeline.json  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
# TO DO/CHECK: this should return a message like this: {"acknowledged":true}
if [[ $response != 2* ]]; then
   log_error "There was an issue loading ingest pipeline into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Ingest pipeline definition loaded into Elasticsearch [$response]"
fi

# Link index management policy and Ingest Pipeline to Index Template
response=$(curl  -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_template/viya-logs-template "    -H 'Content-Type: application/json' -d @logging/es/odfe/es_set_index_template_settings_logs.json --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure )
# TO DO/CHECK: this should return a message like this: {"acknowledged":true}
if [[ $response != 2* ]]; then
   log_error "There was an issue loading index template settings into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Index template settings loaded into Elasticsearch [$response]"
fi

# METALOGGING: Create index management policy object & link policy to index template
# ...index management policy automates the deletion of indexes after the specified time
response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_opendistro/_ism/policies/viya_ops_idxmgmt_policy" -H 'Content-Type: application/json' -d @logging/es/odfe/es_viya_ops_idxmgmt_policy.json  --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure )
# TO DO/CHECK: this should return the JSON policy definition back rather than the simpler {"acknowledged":true}
if [[ $response == 409 ]]; then
   log_info "Monitoring index management policies already exist in Elasticsearch. Skipping load."
elif [[ $response != 2* ]]; then
   log_error "There was an issue loading monitoring index management policies into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Monitoring index management policies loaded into Elasticsearch [$response]"
fi

response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_template/viya-ops-template " -H 'Content-Type: application/json' -d @logging/es/odfe/es_set_index_template_settings_ops.json --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
# TO DO/CHECK: this should return a message like this: {"acknowledged":true}
if [[ $response != 2* ]]; then
   log_error "There was an issue loading monitoring index template settings into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Monitoring index template template settings loaded into Elasticsearch [$response]"
fi
echo ""

# Set ISM Job Interval to 120 minutes (from default 5 minutes)
response=$(curl -s -o /dev/null -w "%{http_code}" -XPUT "https://localhost:$TEMP_PORT/_cluster/settings" -H 'Content-Type: application/json' -d @logging/es/odfe/es_set_index_job_interval.json --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure)
# TODO: Check the result is a messsge like: {"acknowledged":true,"persistent":{"opendistro":{"index_state_management":{"job_interval":"120"}}},"transient":{}}
if [[ $response != 2* ]]; then
   log_error "There was an issue loading cluster setttings into Elasticsearch [$response]"
   kill -9 $pfPID
   exit 16
else
   log_info "Cluster settings loaded into Elasticsearch [$response]"
fi

# terminate port-forwarding and remove tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
rm -f $tmpfile

sleep 7s


log_info "STEP 3: Deploying Elasticsearch metric exporter"

ELASTICSEARCH_EXPORTER_ENABLED=${ELASTICSEARCH_EXPORTER_ENABLED:-true}
if [ "$ELASTICSEARCH_EXPORTER_ENABLED" == "true" ]; then
   # Elasticsearch metric exporter
   if [ "$HELM_VER_MAJOR" == "3" ]; then
      helm2ReleaseCheck es-exporter-$LOG_NS
      helm $helmDebug upgrade --install es-exporter \
      --namespace $LOG_NS \
      -f logging/es/odfe/values-es-exporter_open.yaml \
      -f $ES_OPEN_EXPORTER_USER_YAML \
      stable/elasticsearch-exporter
   else
      helm3ReleaseCheck es-exporter $LOG_NS
      helm upgrade --install es-exporter-$LOG_NS \
      --namespace $LOG_NS \
      -f logging/es/odfe/values-es-exporter_open.yaml \
      -f $ES_OPEN_EXPORTER_USER_YAML \
      stable/elasticsearch-exporter
   fi
fi

# Kibana
log_info "STEP 4: Configuring Kibana"

# NOTE: For ODFE, Kibana is deployed as part of ES Helm chart

#### TEMP?  Remove when defining nodePort via HELM chart?
SVC=v4m-es-kibana-svc
SVC_TYPE=$(kubectl get svc -n $LOG_NS $SVC -o jsonpath='{.spec.type}')
if [ "$SVC_TYPE" == "NodePort" ]; then
  KIBANA_PORT=31033
  kubectl -n "$LOG_NS" patch svc "$SVC" --type='json' -p '[{"op":"replace","path":"/spec/ports/0/nodePort","value":31033}]'
  log_info "Set Kibana service NodePort to 31033"
fi


# construct URL to access Kibana
# Use existing NODE_NAME or find one
NODE_NAME=${NODE_NAME:-$(kubectl get node --selector='node-role.kubernetes.io/master' | awk 'NR==2 { print $1 }')}
if [ "$NODE_NAME" == "" ]; then
  # Get first node
  NODE_NAME=$(kubectl get nodes | awk 'NR==2 { print $1 }')
fi


# Need to wait 2-3 minutes for kibana to come up and
# and be ready to accept the curl commands below
# wait for pod to show as "running" and "ready"

log_info "Checking status of Kibana pod"
podready="FALSE"

for pause in 40 30 20 15 10 10 10 15 15 15 30 30 30 30
do
   if [[ "$( kubectl -n $LOG_NS get pod -l 'role=kibana' -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')" == *"True"* ]]; then
      log_info "Pod is ready...continuing"
      podready="TRUE"
      break
   else
      log_info "Pod is not ready yet...sleeping for [$pause] more seconds before checking again."
      sleep ${pause}s
   fi
done

if [ "$podready" != "TRUE" ]; then
   log_error "The kibana pod has NOT reached [Ready] status in the expected time; exiting."
   log_error "Review pod's events and log to identify the issue and resolve it; run the remove_logging.sh script and try again."
   exit 15
fi

# wait for pod to come up
log_info "Waiting [4] minutes to allow Kibana to initialize [$(date)] "
sleep 240s


# set up temporary port forwarding to allow curl access
K_PORT=$(kubectl -n $LOG_NS get service v4m-es-kibana-svc -o=jsonpath='{.spec.ports[?(@.name=="kibana-svc")].port}')

# command is sent to run in background
kubectl -n $LOG_NS port-forward  --address localhost svc/v4m-es-kibana-svc :$K_PORT > $tmpfile &

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
   rm -f $tmpfile
  exit 18
fi

# Import Kibana Searches, Visualizations and Dashboard Objects using curl
response=$(curl -s -o /dev/null -w "%{http_code}" -XPOST "$KB_CURL_PROTOCOL://localhost:$TEMP_PORT/api/saved_objects/_import?overwrite=true"  -H "kbn-xsrf: true"   --form file=@logging/kibana/kibana_saved_objects_7.6.1_200915.ndjson --user $ES_ADMIN_USER:$ES_ADMIN_PASSWD --insecure )

# TO DO/CHECK: this should return a SUCCESS message like this: {"success":true,"successCount":20}
if [[ $response != 2* ]]; then
   log_error "There was an issue loading content into Kibana [$response]"
   kill -9 $pfPID
   exit 17
else
   log_info "Content loaded into Kibana [$response]"
fi

# terminate port-forwarding and delete tmpfile
log_info "You may see a message below about a process being killed; it is expected and can be ignored."
kill  -9 $pfPID
rm -f $tmpfile

sleep 7s

# Fluent Bit
if [ "$FLUENT_BIT_ENABLED" == "true" ]; then
   log_info "STEP 5: Deploying Fluent Bit"

   # Call separate Fluent Bit deployment script
   logging/bin/deploy_logging_fluentbit_open.sh
else
  log_info "FLUENT_BIT_ENABLED=[$FLUENT_BIT_ENABLED] - Skipping Fluent Bit install"
fi

log_notice "The deployment of logging components has completed [$(date)]"
echo ""

# Print URL to access Kibana
log_notice "================================================================================"
log_notice "== Access Kibana using this URL: $KB_CURL_PROTOCOL://$NODE_NAME:$KIBANA_PORT/app/kibana =="
log_notice "================================================================================"

