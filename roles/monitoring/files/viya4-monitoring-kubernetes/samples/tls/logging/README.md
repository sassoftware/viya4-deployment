# Sample - TLS Enablement for Logging

## Overview

This sample demonstrates how to deploy logging components with TLS enabled.
For now, only ingress is covered. In-cluster TLS will be supported in the
future.

All components have TLS enabled on ingress. Due to limitations in the
underlying Helm charts, some components might not have TLS enabled in-cluster.

If you use this sample for HTTPS for ingress, the following secrets must be
manually populated in the `logging` namespace (or `LOG_NS` value) **BEFORE**
you run any of the scripts in this repository:

* kubernetes.io/tls secret - `kibana-ingress-tls-secret`
* kubernetes.io/tls secret - `elasticsearch-ingress-tls-secret`

Generating these certificates is outside the scope of this example. However, you
can use the process documented in ["Configure NGINX Ingress TLS for SAS
Applications"](https://go.documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calencryptmotion&docsetTarget=n1xdqv1sezyrahn17erzcunxwix9.htm&locale=en#n0oo2yu8440vmzn19g6xhx4kfbrq) in SAS Viya Administration documentation and specify the `logging` namespace.

## Instructions

1. Set up an empty directory with a `logging` subdirectory to contain the customization files. 

2. Export a `USER_DIR` environment variable that points to this
location. For example:

```bash
mkdir -p ~/my-cluster-files/ops/user-dir/logging
export USER_DIR=~/my-cluster-files/ops/user-dir
```

3. Create `$USER_DIR/logging/user.env`. Specify this value in the file:

* `MON_TLS_ENABLE=true` - This flag modifies the deployment of Open Distro for Elasticsearch to be TLS-enabled.

4. Copy the sample TLS Helm user response file to your `USER_DIR`:

```bash
cp path/to/this/repo/loggingsamples/tls/user-values-elasticsearch-open.yaml $USER_DIR/logging/
```

5. Edit `$USER_DIR/monitoring/user-values-elasticsearch-open.yaml` and replace
any sample hostnames with hostnames for your deployment. Specifically, you must replace
`host.cluster.example.com` with the name of the ingress node. Often, the ingress node is the cluster master node, but environments vary.

6. Specify any other customizations in `user-values-elasticsearch-open.yaml`.

7. Deploy logging using the standard deployment script:

```bash
path/to/this/repo/logging/bin/deploy_logging_cluster.sh
```
