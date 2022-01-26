# syntax=docker/dockerfile:experimental
FROM ubuntu:20.04 as baseline
RUN apt update && apt upgrade -y \
  && apt install -y python3 python3-dev python3-pip curl unzip \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline as tool_builder
ARG kustomize_version=3.7.0
ARG kubectl_version=1.21.8

WORKDIR /build

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v{$kubectl_version}/bin/linux/amd64/kubectl && chmod 755 ./kubectl \
  && curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${kustomize_version}/kustomize_v${kustomize_version}_linux_amd64.tar.gz && gunzip -c ./kustomize_v${kustomize_version}_linux_amd64.tar.gz | tar xvf - && chmod 755 ./kustomize

# Installation
FROM baseline
ARG aws_cli_version=2.1.20
ARG gcp_cli_version=334.0.0

# Add extra packages
RUN apt install -y gzip wget git git-lfs jq sshpass \
  && curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
  && helm plugin install https://github.com/databus23/helm-diff \
  # AWS
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${aws_cli_version}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  # AZURE
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  # GCP
  && curl "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcp_cli_version}-linux-x86_64.tar.gz" -o gcpcli.tar.gz \
  && tar -xvf gcpcli.tar.gz \
  && ./google-cloud-sdk/install.sh

COPY --from=tool_builder /build/kubectl /usr/local/bin/kubectl
COPY --from=tool_builder /build/kustomize /usr/local/bin/kustomize

WORKDIR /viya4-deployment/
COPY . /viya4-deployment/

ENV HOME=/viya4-deployment

RUN pip install -r ./requirements.txt \
  && ansible-galaxy install -r ./requirements.yaml \
  && chmod -R g=u /etc/passwd /etc/group /viya4-deployment/ \
  && chmod 755 /viya4-deployment/docker-entrypoint.sh

ENV PLAYBOOK=playbook.yaml
ENV VIYA4_DEPLOYMENT_TOOLING=docker
ENV ANSIBLE_CONFIG=/viya4-deployment/ansible.cfg
ENV PATH=$PATH:/google-cloud-sdk/bin/

VOLUME ["/data", "/config", "/vault"]
ENTRYPOINT ["/viya4-deployment/docker-entrypoint.sh"]
