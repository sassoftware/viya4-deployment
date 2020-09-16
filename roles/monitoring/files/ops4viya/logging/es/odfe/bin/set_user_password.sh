#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


USERNAME=${1}
PASSWORD=${2}

export ES_PLUGINS_DIR=/usr/share/elasticsearch/plugins
export ES_CONF_DIR=/usr/share/elasticsearch/config

logfile=$ES_CONF_DIR/set_user_password.log
echo "set_user_password.sh script starting [$(date)]" > $logfile

# validate all req parms provided
if [ "$USERNAME" != "" ] && [ "$PASSWORD" != "" ]; then

  #construct env var for username string
  USERNAME_ENV_VAR="ES_"
  USERNAME_ENV_VAR+=$(echo $USERNAME|tr [:lower:] [:upper:])
  USERNAME_ENV_VAR+=_PASSWD

  env_var_file=/etc/profile.d/v4m_reset_passwd.$(date +"%s").sh
  # write out new password
  echo "export $USERNAME_ENV_VAR=$PASSWORD" > $env_var_file

  # source file to set env var
  . $env_var_file

else
  echo "ERROR: Required fields [USERNAME] and/or [PASSWORD] not provided." >> $logfile
  exit 1
fi

if [[ ! -x $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh ]]; then
  chmod +x $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh
fi

#initialize rc
rc=-1
counter=0

while [ $rc != 0 ] && [ $counter -lt 3 ]; do
  echo "Looping: $counter $(date)"

  if [ $rc -gt 0 ]; then sleep 30s; fi

  # reload internal users file only
  $ES_PLUGINS_DIR/opendistro_security/tools/securityadmin.sh  -icl -key "$ES_CONF_DIR/admin-key.pem" -cert "$ES_CONF_DIR/admin-crt.pem" -cacert "$ES_CONF_DIR/admin-root-ca.pem" -nhnv -rev --file $ES_PLUGINS_DIR/opendistro_security/securityconfig/internal_users.yml --type internalusers >> $logfile

  rc=$?
  echo "RC: $rc"
  ((counter++))
done

if [ $rc != 0 ]; then
  rm $env_var_file
  echo "ERROR: Unable to (re-)set the internal user password for [$USERNAME]." >> $logfile
  exit 2
fi
