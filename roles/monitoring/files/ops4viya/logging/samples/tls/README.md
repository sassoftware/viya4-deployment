# Sample - TLS Enablement for Logging

## Overview

This sample demonstrates how to deploy logging components with TLS enabled.
For now, only ingress is covered. In-cluster TLS will be supported in the
future.

All components have TLS enabled on ingress. Due to limitations in the
underlying Helm charts, some components might not have TLS enabled in-cluster.
See the Limitations and Known Issues section below for details.

If you use this sample for HTTPS for ingress, the following secrets must be
manually populated in the `logging` namespace (or `LOG_NS` value) **BEFORE**
you run any of the scripts in this repository:

* kubernetes.io/tls secret - `kibana-ingress-tls-secret`
* kubernetes.io/tls secret - `elasticsearch-ingress-tls-secret`

Generating these certificates is outside the scope of this example.However, you
can use the process documented in "Configure NGINX Ingress TLS for SAS
Applications" in SAS Viya Administation documentation and specify the `logging`
namespace.
