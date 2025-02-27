#!/bin/bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## installs this by default:
#   - INGRESS_NGINX_CVE_2021_25742_PATCH
#   - ingress-nginx private ingress

source 00_vars.sh 

# helm registry login
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

read -p "ingress-nginx helm chart version: " CHART_VERSION
read -p "controller image digest (sha256): " CONTROLLER_DIGEST
read -p "webhook image digest (sha256): " WEBHOOK_DIGEST
read -p 'load balancer source ranges? must be a list (example): ["0.0.0.0/0"] ' LB

# handle version differences with webhook path
CHART_VERSION_INT=$(echo "${CHART_VERSION//.}")
if [ $CHART_VERSION_INT -lt 411 ]; then
     WEBHOOK_PATH=jettech
elif [ $CHART_VERSION_INT -ge 411 ]; then
     WEBHOOK_PATH=ingress-nginx
else
     echo "Error with your helm chart versions!  Exiting..."
     exit 1
fi

read -r -d '' TMP_YAML <<EOF
controller:
     image:
          registry: ${AWS_ACCT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
          image: ingress-nginx/controller
          digest: ${CONTROLLER_DIGEST}
     admissionWebhooks:
          patch:
               image:
                    registry: ${AWS_ACCT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    image: ${WEBHOOK_PATH}/kube-webhook-certgen
                    digest: ${WEBHOOK_DIGEST}
     service: 
          externalTrafficPolicy: Local
          sessionAffinity: None
          loadBalancerSourceRanges: ${LB}
          annotations:
               service.beta.kubernetes.io/aws-load-balancer-internal: "true"
               service.beta.kubernetes.io/aws-load-balancer-type: nlb       
     config:
          use-forwarded-headers: "false"
          hsts-max-age: "63072000"
          allow-snippet-annotations: "true"
          large-client-header-buffers: "4 32k"
          annotation-value-word-blocklist: 'load_module,lua_package,_by_lua,location,root,proxy_pass,serviceaccount,{,},\\'
     tcp: {}
     udp: {}
     lifecycle:
          preStop:
               exec:
                    command: ["/bin/sh", "-c", "sleep 5; /usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf -s quit; while pgrep -x nginx; do sleep 1; done"]
     terminationGracePeriodSeconds: 600

EOF
echo "${TMP_YAML}" > tmp.yaml

# helm install
echo -e "\nInstalling ingress-nginx...\n"
helm upgrade --cleanup-on-fail \
     --install ingress-nginx oci://$AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ingress-nginx --version=$CHART_VERSION \
     --values tmp.yaml \
     --namespace ingress-nginx \
     --create-namespace

# cleanup
unset TMP_YAML
rm tmp.yaml
