#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

source 00_vars.sh

. auto_scaler.sh
. cert_manager.sh
. ingress_nginx.sh
. metrics_server.sh
. nfs_subdir_external_provisioner.sh
. openldap.sh
. ebs_driver.sh
