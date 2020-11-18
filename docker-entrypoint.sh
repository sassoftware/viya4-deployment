#!/usr/bin/env bash
set -e

OPTS="-e BASE_DIR=/data"

for MOUNT in "/config"/*
do
  base=$(basename $MOUNT)
  VAR=${base^^}

  if [[ "$VAR" == "VAULT_PASSWORD_FILE" ]]; then
    OPTS+=" --vault-password-file $MOUNT"
  else
    OPTS+=" -e $VAR=$MOUNT"
  fi
done

echo  "Running: ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}"
exec ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}