# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This file is not marked as executable as it is intended to be sourced
# Current directory must be the root directory of the repo

if [ "$SAS_COMMON_SOURCED" = "" ]; then
    # Includes
    source bin/colors-include.sh
    source bin/log-include.sh
    source bin/helm-include.sh
    source bin/kube-include.sh

    export USER_DIR=${USER_DIR:-$(pwd)}
    if [ -f "$USER_DIR/user.env" ]; then
        userEnv=$(grep -v '^[[:blank:]]*$' $USER_DIR/user.env | grep -v '^#' | xargs)
        if [ "$userEnv" != "" ]; then
          log_debug "Loading global user environment file: $USER_DIR/user.env"
          if [ "$userEnv" != "" ]; then
            export $userEnv
          fi
        fi
    fi

    log_debug "Working directory: $(pwd)"
    log_debug "User directory: $USER_DIR"
    log_info "Helm client version: $HELM_VER_FULL"
    if [ "$HELM_VER_MAJOR" == "2" ] && [ "$HELM_SERVER_VER_FULL" != "" ]; then
      log_info "Helm server version: $HELM_SERVER_VER_FULL"
    fi

    log_info Kubernetes client version: "$KUBE_CLIENT_VER"
    log_info Kubernetes server version: "$KUBE_SERVER_VER"

    export TMP_DIR=$(mktemp -d -t sas.mon.XXXXXXXX)
    if [ ! -d "$TMP_DIR" ]; then
      log_error "Could not create temporary directory [$TMP_DIR]"
      exit 1
    fi
    log_debug "Temporary directory: [$TMP_DIR]"
    echo "# This file intentionally empty" > $TMP_DIR/empty.yaml

    # Delete the temp directory on exit
    function cleanup {
      rm -rf "$TMP_DIR"
      log_debug "Deleted temporary directory: [$TMP_DIR]"
    }
    trap cleanup EXIT

    export SAS_COMMON_SOURCED=true
fi

function checkDefaultStorageClass {
    if [ -z "$defaultStorageClass" ]; then
      # Check for kubernetes environment conflicts/requirements
      defaultStorageClass=$(kubectl get storageclass -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.metadata.annotations..storageclass\.kubernetes\.io/is-default-class}{'\n'}{end}" | grep true | awk '{print $1}')
      if [ "$defaultStorageClass" ]; then
        log_debug "Found default storageClass: [$defaultStorageClass]"
      else
        # Try again with beta storageclass annotation key
        defaultStorageClass=$(kubectl get storageclass -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.metadata.annotations..storageclass\.beta\.kubernetes\.io/is-default-class}{'\n'}{end}" | grep true | awk '{print $1}')
        if [ "$defaultStorageClass" ]; then
          log_debug "Found default storageClass: [$defaultStorageClass]"
        else
          log_warn "This cluster does not have a default storageclass defined"
          log_warn "This may cause errors unless storageclass values are explicitly defined"
          defaultStorageClass=_NONE_
        fi
      fi
    fi
}