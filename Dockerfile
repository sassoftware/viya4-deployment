# syntax=docker/dockerfile:experimental
FROM ubuntu:22.04 as baseline

RUN apt-get update && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y python3 python3-dev python3-pip curl unzip apt-transport-https ca-certificates gnupg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline as tool_builder
ARG kubectl_version=1.28.7

WORKDIR /build

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$kubectl_version/bin/linux/amd64/kubectl && chmod 755 ./kubectl

# Installation
FROM baseline
ARG helm_version=3.15.2
ARG aws_cli_version=2.16.5
ARG gcp_cli_version=479.0.0-0

# Add extra packages
RUN apt-get update && apt-get install --no-install-recommends -y gzip wget git jq ssh sshpass skopeo rsync \
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
