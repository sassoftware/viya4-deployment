#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


export ES_PLUGINS_DIR=/usr/share/elasticsearch/plugins
export ES_CONF_DIR=/usr/share/elasticsearch/config

logfile=$ES_CONF_DIR/run_securityadmin.log
echo "run_securityadmin.sh script starting [$(date)]" > $logfile

if [[ ! -x $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh ]]; then
   echo "Setting eXecutable bit"
  chmod +x $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh
fi

#initialize rc
rc=-1
counter=0

while [ $rc != 0 ] && [ $counter -lt 3 ]; do
  echo "Looping: $counter $(date)"
  if [ $rc -gt 0 ]; then sleep 30s; fi
  $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh -cd "$ES_PLUGINS_DIR/opendistro_security/securityconfig" -icl -key "$ES_CONF_DIR/admin-key.pem" -cert "$ES_CONF_DIR/admin-crt.pem" -cacert "$ES_CONF_DIR/admin-root-ca.pem" -nhnv -rev >> $logfile
  rc=$?
  echo "RC: $rc"
  ((counter++))
done
