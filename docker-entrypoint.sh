#!/usr/bin/env bash
set -e

OPTS=" -e BASE_DIR=/data"

for FILE in "/config"/*
do
  if [[ -f "$FILE" ]]
  then
    VAR=$(basename $FILE)
    OPTS+=" -e ${VAR^^}=$FILE"
  fi
done

exec ansible-playbook $OPTS $@ playbooks/${PLAYBOOK}