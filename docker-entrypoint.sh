#!/usr/bin/env bash
set -e

# setup container user
echo "viya4-deployment:*:$(id -u):$(id -g):,,,:/viya4-deployment:/bin/bash" >> /etc/passwd
echo "viya4-deployment:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

OPTS="-e BASE_DIR=/data"

for MOUNT in "/config"/*
do
  base=$(basename $MOUNT)
  VAR=${base^^}

  if [[ "$VAR" == "VAULT_PASSWORD_FILE" ]]; then
    OPTS+=" --vault-password-file $MOUNT"
  elif [[ "$VAR" == "V4_CFG_CLOUD_SERVICE_ACCOUNT_AUTH" ]]; then
    export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=$MOUNT
  else
    OPTS+=" -e $VAR=$MOUNT"
  fi
done

echo  "Running: ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}"
exec ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}
