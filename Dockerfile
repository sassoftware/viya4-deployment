# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

ARG TERRAFORM_VERSION=1.10.5
ARG GCP_CLI_VERSION=513.0.0

FROM hashicorp/terraform:$TERRAFORM_VERSION AS terraform
FROM google/cloud-sdk:$GCP_CLI_VERSION-alpine
ARG KUBECTL_VERSION=1.34.6
ARG ENABLE_GKE_GCLOUD_AUTH_PLUGIN=True
ARG INSTALL_COMPONENTS=""

WORKDIR /viya4-iac-gcp

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN apk update \
  && apk upgrade --no-cache \
  && apk add --no-cache jq \
  && curl -sLO https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-gcp/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && git config --system --add safe.directory /viya4-iac-gcp \
  && terraform init \
  && gcloud components install gke-gcloud-auth-plugin alpha beta cloud-sql-proxy $INSTALL_COMPONENTS \
  && rm -rf /google-cloud-sdk/.install/.backup \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-gcp

ENV TF_VAR_iac_tooling=docker
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=$ENABLE_GKE_GCLOUD_AUTH_PLUGIN
ENTRYPOINT ["/viya4-iac-gcp/docker-entrypoint.sh"]
VOLUME ["/workspace"]
