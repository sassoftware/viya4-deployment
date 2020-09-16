#! /bin/bash

# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This file is not marked as executable as it is intended to be sourced
# Current directory must be the root directory of the repo

function create_secret_from_file {

  file=$1
  secret_name=$2

  if [ -z "$(kubectl -n $LOG_NS get secret $secret_name -o name 2>/dev/null)" ]; then

    log_debug "Will attempt to create secret [$secret_name]"

    if [ -f "$USER_DIR/logging/$file" ]; then filepath=$USER_DIR/logging
    elif [ -f "logging/es/odfe/$file" ]; then filepath=logging/es/odfe
    else
      log_error "Could not create secret [$secret_name] because file [$file] could not be found"
      return 9
    fi

    if [ "$(kubectl -n $LOG_NS create secret generic $secret_name --from-file=$filepath/$file)" == "secret/$secret_name created" ]; then
      log_info "Created secret for Elasticsearch config file [$file]"
      return 0
    else
      log_error "Could not create secret for Elasticsearch config file [$file]"
      return 8
    fi
  else
    log_info "Using existing secret [$secret_name]"
    return 0
  fi
}

function create_user_secret {
  secret_name=$1
  username=$2
  password=$3

  if [ -z "$(kubectl -n $LOG_NS get secret $secret_name -o name 2>/dev/null)" ]; then

    log_debug "Will attempt to create secret [$secret_name]"

    if [ "$(kubectl -n $LOG_NS create secret generic $secret_name  --from-literal=username=$username --from-literal=password=$password)" == "secret/$secret_name created" ]; then
      log_info "Created secret for Elasticsearch user credentials [$username]"
      return 0
    else
      log_error "Could not create secret for Elasticsearch user credentials [$username]"
      return 111
    fi
  else
    log_info "Using existing secret [$secret_name]"
    return 0
  fi
}
