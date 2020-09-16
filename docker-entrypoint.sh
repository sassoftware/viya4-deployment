#!/usr/bin/env bash

set -e
FILES=("kube" "sitedefault" "sssd" "config" "tfstate" "jump_svr_private_key")
OPTS="-e BASE_DIR=${BASE_DIR}"

for FILE in ${FILES[@]}; do
  if [ -f "/config/$FILE" ]; then
    OPTS+=" -e ${FILE^^}=/config/$FILE"
  fi
done

exec ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}