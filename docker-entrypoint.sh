#!/usr/bin/env bash

# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

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
  else
    OPTS+=" -e $VAR=$MOUNT"
  fi
done

# TODO: Can remove the next line when DAC moves to kubectl >= 1.26
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
echo  "Running: ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}"
ANSIBLE_STDOUT_CALLBACK=yaml exec ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}
