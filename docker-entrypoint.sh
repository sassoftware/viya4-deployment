#!/usr/bin/env bash
set -e

echo "viya4-deployment:x:$(id -u):$(id -g):Viya4:/viya4-deployment:/bin/bash" >> /etc/passwd
echo "viya4-deployment:x:$(id -G | cut -d' ' -f 1):" >> /etc/group

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
