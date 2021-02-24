# syntax=docker/dockerfile:experimental
FROM ubuntu:20.04 as baseline
RUN apt-get update && apt-get -y upgrade \
  && apt-get -y install python3 python3-dev python3-pip curl unzip \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline as tool_builder
ARG terraform_version=0.13.6
ARG kustomize_version=3.7.0
ARG kubectl_version=1.18.8
ARG aws_iam_authenticator_version="1.18.9/2020-11-02"

WORKDIR /build

RUN curl -sLO https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip && unzip ./terraform_${terraform_version}_linux_amd64.zip \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v{$kubectl_version}/bin/linux/amd64/kubectl && chmod 755 ./kubectl \
  && curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${kustomize_version}/kustomize_v${kustomize_version}_linux_amd64.tar.gz && gunzip -c ./kustomize_v${kustomize_version}_linux_amd64.tar.gz | tar xvf - && chmod 755 ./kustomize \
  && curl -sLO https://amazon-eks.s3.us-west-2.amazonaws.com/${aws_iam_authenticator_version}/bin/linux/amd64/aws-iam-authenticator && chmod 755 aws-iam-authenticator 

# Installation
FROM baseline

# Add extra packages
RUN apt-get -y install gzip wget git git-lfs jq sshpass \
  && curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
  && pip install openshift "ansible>=2.9,<3.0.0" dnspython 

COPY --from=tool_builder /build/terraform /usr/local/bin/terraform
COPY --from=tool_builder /build/kubectl /usr/local/bin/kubectl
COPY --from=tool_builder /build/kustomize /usr/local/bin/kustomize
COPY --from=tool_builder /build/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

WORKDIR /viya4-deployment/
COPY . /viya4-deployment/

RUN ansible-galaxy collection install -r requirements.yaml -f \
  && chmod -R g=u /etc/passwd /etc/group /viya4-deployment/ \
  && chmod 755 /viya4-deployment/docker-entrypoint.sh

ENV PLAYBOOK=playbook.yaml 
ENV VIYA4_DEPLOYMENT_TOOLING=docker
ENV HOME=/viya4-deployment
ENV ANSIBLE_CONFIG=/viya4-deployment/ansible.cfg

VOLUME ["/data", "/config", "/vault"]
ENTRYPOINT ["/viya4-deployment/docker-entrypoint.sh"]
