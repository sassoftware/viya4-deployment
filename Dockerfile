# syntax=docker/dockerfile:experimental
FROM ubuntu:22.04 AS baseline

RUN apt-get update && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y python3 python3-dev python3-pip curl unzip apt-transport-https ca-certificates gnupg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline AS tool_builder
ARG kubectl_version=1.30.10

WORKDIR /build

RUN curl -sLO https://dl.k8s.io/release/v$kubectl_version/bin/linux/amd64/kubectl && chmod 755 ./kubectl

# Build Skopeo from source since the version in the apt repository is outdated
FROM golang:alpine3.20 AS golang
ARG SKOPEO_VERSION=release-1.16
RUN apk add --no-cache git build-base containers-common bash btrfs-progs-dev glib-dev go go-md2man gpgme-dev libselinux-dev linux-headers lvm2-dev ostree-dev \
  && git clone https://github.com/containers/skopeo.git -b $SKOPEO_VERSION \
  && DISABLE_DOCS=1 make -C skopeo bin/skopeo.linux.386

# Installation
FROM baseline
ARG helm_version=3.17.1
ARG aws_cli_version=2.24.16
ARG gcp_cli_version=513.0.0-0

# Add extra packages
RUN apt-get update && apt-get install --no-install-recommends -y gzip wget git jq ssh sshpass rsync \
  && rm -f /etc/ssh/ssh_host_rsa_key && rm -f /etc/ssh/ssh_host_ecdsa_key && rm -f /etc/ssh/ssh_host_ed25519_key \
  && curl -ksLO https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 755 get-helm-3 \
  && ./get-helm-3 --version v$helm_version --no-sudo \
  # AWS
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${aws_cli_version}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  # AZURE
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  # GCP
  && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update && apt-get install --no-install-recommends -y google-cloud-cli:amd64=${gcp_cli_version} \
  && apt-get install --no-install-recommends -y google-cloud-sdk-gke-gcloud-auth-plugin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=tool_builder /build/kubectl /usr/local/bin/kubectl
COPY --from=golang /go/skopeo/bin/skopeo.linux.386 /usr/local/bin/skopeo

WORKDIR /viya4-deployment/
COPY . /viya4-deployment/

ENV HOME=/viya4-deployment

RUN pip install -r ./requirements.txt \
  && ansible-galaxy install -r ./requirements.yaml \
  && rm -rf /usr/local/lib/python3.10/dist-packages/ansible_collections/infinidat \
  && rm -rf /usr/local/lib/python3.10/dist-packages/ansible_collections/netbox \
  && pip cache purge \
  && chmod -R g=u /etc/passwd /etc/group /viya4-deployment/ \
  && chmod 755 /viya4-deployment/docker-entrypoint.sh \
  && git config --system --add safe.directory /viya4-deployment ||:

ENV PLAYBOOK=playbook.yaml
ENV VIYA4_DEPLOYMENT_TOOLING=docker
ENV ANSIBLE_CONFIG=/viya4-deployment/ansible.cfg

VOLUME ["/data", "/config", "/vault"]
ENTRYPOINT ["/viya4-deployment/docker-entrypoint.sh"]
