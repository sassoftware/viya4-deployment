# syntax=docker/dockerfile:experimental

FROM golang:1.15 as go_builder
RUN go get github.com/google/go-jsonnet/cmd/jsonnet && go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && go get github.com/brancz/gojsontoyaml

FROM ubuntu:20.04 as baseline
WORKDIR /build
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install python3 python3-dev python3-pip curl unzip
# Adjust python to use only Python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline as tool_builder
ENV terraform_version=0.13.2
ENV kubectl_version=1.18.8
ENV kustomize_version=3.6.1
RUN curl -sLO https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip && unzip ./terraform_${terraform_version}_linux_amd64.zip \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v{$kubectl_version}/bin/linux/amd64/kubectl && chmod 755 ./kubectl \
  && curl -s https://sdk.cloud.google.com | bash \
  && curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${kustomize_version}/kustomize_v${kustomize_version}_linux_amd64.tar.gz && gunzip -c ./kustomize_v${kustomize_version}_linux_amd64.tar.gz | tar xvf - && chmod 755 ./kustomize

# Installation
FROM baseline
WORKDIR /cloud-deployment

COPY --from=go_builder /go/bin/jsonnet /usr/local/bin/jsonnet
COPY --from=go_builder /go/bin/jb /usr/local/bin/jb
COPY --from=go_builder /go/bin/gojsontoyaml /usr/local/bin/gojsontoyaml
COPY --from=tool_builder /build/terraform /usr/local/bin/terraform
COPY --from=tool_builder /build/kubectl /usr/local/bin/kubectl
COPY --from=tool_builder /build/kustomize /usr/local/bin/kustomize
COPY --from=tool_builder /root/google-cloud-sdk /cloud/clis/google-cloud-sdk

# Add extra packages
RUN apt-get -y install gzip wget bash-completion git git-lfs jq sshpass ansible  \
  && curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash \
  && pip install openshift \
  && curl -sLO https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip && unzip awscli-exe-linux-x86_64.zip && ./aws/install && rm -rf awscli-exe-linux-x86_64.zip \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && echo 'source /etc/profile.d/bash_completion.sh\nsource <(kubectl completion bash)\nalias k=kubectl\ncomplete -F __start_kubectl k' >> ~/.bashrc \
  && echo 'source /cloud/clis/google-cloud-sdk/completion.bash.inc' >> ~/.bashrc \
  && echo 'source /cloud/clis/google-cloud-sdk/path.bash.inc' >> ~/.bashrc

COPY . /cloud-deployment/
RUN ansible-galaxy collection install -r requirements.yaml -f \
  && chmod +x /cloud-deployment/docker-entrypoint.sh

VOLUME ["/data", "/config"]

ENV BASE_DIR=/data
ENV PLAYBOOK=playbook.yaml

ENTRYPOINT ["/cloud-deployment/docker-entrypoint.sh"]