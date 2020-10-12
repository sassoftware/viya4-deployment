# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Logging helper functions

colorEnable=${LOG_COLOR_ENABLE:-true}
levelEnable=${LOG_LEVEL_ENABLE:-true}
logDebug=${LOG_DEBUG_ENABLE:-false}

function log_notice {
  if [ "$colorEnable" = "true" ]; then
    whiteb "${bluebg}$*"
  else
    echo $*
  fi
}

function log_message {
    echo $*
}

function log_debug {
  if [ "$logDebug" = "true" ]; then
    if [ "$levelEnable" = "true" ]; then
        level="DEBUG "
    else
        level=""
    fi
    if [ "$colorEnable" = "true" ]; then
        echo -e "${whiteb}${level}${white}$*${end}"
    else
        echo $*
    fi
  fi
}

function log_info {
  if [ "$levelEnable" = "true" ]; then
    level="INFO "
  else
    level=""
  fi
  if [ "$colorEnable" = "true" ]; then
    echo -e "${greenb}${level}${whiteb}$*${end}"
  else
    echo $*
  fi
}

function log_warn {
  if [ "$levelEnable" = "true" ]; then
    level="WARN "
  else
    level=""
  fi
  if [ "$colorEnable" = "true" ]; then
    echo -e "${black}${yellowbg}${level}$*${end}"
  else
    echo $*
  fi
}

function log_error {
  if [ "$levelEnable" = "true" ]; then
    level="ERROR "
  else
    level=""
  fi
  if [ "$colorEnable" = "true" ]; then
    echo -e "${whiteb}${redbg}${level}$*${end}"
  else
    echo $*
  fi
}

export -f log_notice log_message log_debug log_info log_warn log_error
export colorEnable levelEnable logDebug
