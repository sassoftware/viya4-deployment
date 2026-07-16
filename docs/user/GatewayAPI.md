# Gateway API + Envoy Gateway - Implementation Guide

## Table of Contents

- [Gateway API + Envoy Gateway - Implementation Guide](#gateway-api--envoy-gateway---implementation-guide)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Architecture](#architecture)
    - [Component Roles](#component-roles)
    - [Traffic Flow](#traffic-flow)
  - [Important Considerations](#important-considerations)
    - [Mutual Exclusivity with Traditional Ingress Controllers](#mutual-exclusivity-with-traditional-ingress-controllers)
    - [Azure Security Policy (NSG)](#azure-security-policy-nsg)
    - [TLS Certificate Requirement](#tls-certificate-requirement)
    - [Backend Service Requirement](#backend-service-requirement)
  - [Configuration Variables](#configuration-variables)
    - [Baseline Settings (roles/baseline/defaults/main.yml)](#baseline-settings-rolesbaselinedefaultsmainyml)
    - [VDM Settings (roles/vdm/defaults/main.yaml)](#vdm-settings-rolesvdmdefaultsmainyaml)
    - [Default Configuration (Gateway API Disabled)](#default-configuration-gateway-api-disabled)
    - [Enable Gateway API in ansible-vars.yaml](#enable-gateway-api-in-ansible-varsyaml)
  - [Implementation Details](#implementation-details)
    - [Gateway API CRD Installation](#gateway-api-crd-installation)
    - [Envoy Gateway Controller](#envoy-gateway-controller)
    - [GatewayClass Resource](#gatewayclass-resource)
    - [Gateway Resource](#gateway-resource)
    - [HTTPRoute Resource](#httproute-resource)
    - [TLS Termination](#tls-termination)
  - [Azure-Specific Behavior](#azure-specific-behavior)
    - [Internal Load Balancer (Recommended)](#internal-load-balancer-recommended)
    - [NSG Security Policy Compliance](#nsg-security-policy-compliance)
  - [Key Benefits](#key-benefits)
  - [Supported TLS Modes](#supported-tls-modes)
  - [Usage](#usage)
    - [Quick Start - Minimal Configuration](#quick-start---minimal-configuration)
    - [Full Azure Private Deployment](#full-azure-private-deployment)
    - [Advanced Configuration](#advanced-configuration)
  - [Validation](#validation)
    - [Comprehensive Validation Sequence](#comprehensive-validation-sequence)
    - [Expected Healthy State](#expected-healthy-state)
  - [Multi-Service Routing](#multi-service-routing)
    - [Current Single-Route Model](#current-single-route-model)
    - [Full Viya Service Routing via Ingress Conversion](#full-viya-service-routing-via-ingress-conversion)
  - [Troubleshooting](#troubleshooting)
    - [Gateway Programmed=False](#gateway-programmedfalse)
    - [Envoy Proxy 1/2 Containers Ready](#envoy-proxy-12-containers-ready)
    - [Security Policy Violation (NSG 443/80)](#security-policy-violation-nsg-44380)
    - [HTTPRoute Not Accepting Traffic](#httproute-not-accepting-traffic)
  - [Known Limitations](#known-limitations)

## Overview

This implementation adds optional support for **Gateway API v1.5.0** and **Envoy Gateway v1.8.0** as the ingress layer for SAS Viya deployments. Gateway API is the Kubernetes-standard successor to the traditional `Ingress` resource model, providing richer routing semantics, explicit role separation, and better multi-tenancy support.

**Note**: As of this implementation, Gateway API support is **disabled by default** to maintain backwards compatibility with existing Contour and nginx-based deployments. It must be explicitly enabled.

This feature was introduced as part of **ADR 0151 (Kubernetes Ingress Support Strategy)**, which requires support for Gateway API v1.5.0 (minimum) and Envoy Gateway v1.8.0 (minimum).

**Release alignment note**: Deployment assets for Gateway API and Envoy Gateway are available in recent cadences (including 2026.06), while broader product-level official support milestones may be tracked separately by release governance (for example, 2026.11).

**UDA interoperability note**: Some UDA cluster setups provision both `gw-system` and `envoy-gateway-system`. This repository relies on `envoy-gateway-system` for Envoy Gateway controller and data-plane resources.

## Architecture

### Component Roles

| Component | Role | Namespace |
|---|---|---|
| Gateway API CRDs | Kubernetes resource type definitions (`Gateway`, `HTTPRoute`, `GatewayClass`, etc.) | Cluster-scoped |
| Envoy Gateway controller | Watches `Gateway` and `HTTPRoute` resources and programs Envoy data plane | `envoy-gateway-system` |
| GatewayClass | Declares a gateway implementation (`envoy`) | Cluster-scoped |
| Gateway | Defines the HTTPS/HTTP listener, hostname, and TLS certificate reference | Viya namespace |
| HTTPRoute | Routes traffic from Gateway to Viya backend services | Viya namespace |
| Envoy proxy (data plane) | Created automatically by Envoy Gateway per Gateway resource; handles actual traffic | `envoy-gateway-system` |
| `envoy-gateway` secret | Internal TLS material for the Envoy Gateway controller itself | `envoy-gateway-system` |
| `sas-ingress-certificate` secret | TLS certificate for the Gateway HTTPS listener | Gateway namespace (`V4_CFG_VIYA_GATEWAY_NAMESPACE`, defaults to Viya namespace) |

### Traffic Flow

```
Client
  │
  ▼
Azure Load Balancer (port 443)
  │
  ▼
Envoy Proxy Pod  (envoy-gateway-system)
  │  TLS terminated here using sas-ingress-certificate
  ▼
HTTPRoute rules matched
  │
  ▼
Viya backend Service  (viya4 namespace)
  │  e.g. sas-logon-app:443
  ▼
Viya Pod
```

## Important Considerations

### Mutual Exclusivity with Traditional Ingress Controllers

When `V4_CFG_GENERATE_GATEWAY_API_RESOURCES=true`, the deployment framework automatically sets `V4_CFG_INGRESS_TYPE=none` at runtime, which prevents Contour, ingress-nginx, and Istio from being installed in the same deployment run. This avoids:

- Duplicate public LoadBalancer services exposing the same ports
- Conflicting NSG/firewall rules
- Multiple ingress paths serving the same traffic

If you previously had Contour deployed, run a baseline uninstall before switching to Gateway API mode:
```bash
# Re-run with baseline+uninstall to remove Contour
docker run ... --tags "baseline,uninstall"
```

### Azure Security Policy (NSG)

Azure enforces security policies against publicly exposed ports. When the Envoy Gateway creates a LoadBalancer service, Azure will:
- Open an NSG rule for that port
- If the rule is public (0.0.0.0/0), Azure security policy will auto-restrict it and send a security violation notification

To avoid security policy violations:
- Always set `V4_CFG_INGRESS_MODE: private` for Azure deployments
- This annotates the Envoy-generated LoadBalancer service with `service.beta.kubernetes.io/azure-load-balancer-internal: "true"`
- The LoadBalancer receives only an internal (VNet) IP, never a public IP

### Hostname Convention

The deployment uses the value of `V4_CFG_INGRESS_FQDN` as the Gateway listener hostname. If your environment follows a naming convention that includes `envoy-gateway` in the FQDN, provide that value directly in `V4_CFG_INGRESS_FQDN`.

### TLS Certificate Requirement

The `Gateway` resource references a secret named `sas-ingress-certificate` in the Gateway resource namespace (`V4_CFG_VIYA_GATEWAY_NAMESPACE`). Envoy Gateway will not fully program the listener until this secret exists. The secret must contain:

- `tls.crt` — Certificate (PEM format)
- `tls.key` — Private key (PEM format)

The framework creates this secret automatically when:
- `V4_CFG_TLS_CERT` and `V4_CFG_TLS_KEY` are provided (customer certificates), or
- `V4_CFG_TLS_GENERATOR: openssl` is set (auto-generated by the SAS certframe job during Viya deployment)

If the secret is missing and you need to recover manually:
```bash
kubectl create secret tls sas-ingress-certificate \
  --cert=/path/to/cert.crt \
  --key=/path/to/cert.key \
  -n <gateway-namespace>
```

### Backend Service Requirement

The `HTTPRoute` resource routes traffic to a Viya backend service. The service named in `V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE` must exist in the Viya namespace. Common valid choices when TLS mode is not disabled:

| Service Name | Purpose | Port |
|---|---|---|
| `sas-logon-app` | SAS Logon (exposes `/SASLogon`) | 443 |
| `sas-visual-analytics-app` | SAS Visual Analytics | 443 |
| `sas-studio-app` | SAS Studio | 443 |
| `sas-landing-app` | SAS Home / landing page | 443 |

For full Viya application coverage, multiple HTTPRoute resources are needed. See [Multi-Service Routing](#multi-service-routing).

## Configuration Variables

### Baseline Settings (roles/baseline/defaults/main.yml)

**Important**: `V4_CFG_INSTALL_GATEWAY_API` and `V4_CFG_INSTALL_ENVOY_GATEWAY` are independent feature flags. Both must be `true` for a complete setup.

| Variable | Default | Description |
|---|---|---|
| `V4_CFG_INSTALL_GATEWAY_API` | `false` | Install Gateway API CRDs into the cluster |
| `V4_CFG_INSTALL_ENVOY_GATEWAY` | `false` | Install Envoy Gateway controller |
| `GATEWAY_API_VERSION` | `v1.5.0` | Gateway API CRD version to install |
| `GATEWAY_API_NAMESPACE_LABEL_MODE` | `standard` | CRD channel: `standard` or `experimental` |
| `ENVOY_GATEWAY_VERSION` | `v1.8.0` | Envoy Gateway controller version |
| `ENVOY_GATEWAY_GATEWAYCLASS_NAME` | `envoy` | Name of the GatewayClass resource created automatically |

### VDM Settings (roles/vdm/defaults/main.yaml)

| Variable | Default | Required | Description |
|---|---|---|---|
| `V4_CFG_GENERATE_GATEWAY_API_RESOURCES` | `false` | No | Generate Gateway and HTTPRoute Kubernetes resources during Viya deployment |
| `V4_CFG_VIYA_GATEWAY_NAME` | `sas-viya-gateway` | No | Name of the Gateway resource |
| `V4_CFG_VIYA_GATEWAY_CLASS_NAME` | `envoy` | No | GatewayClass to reference in the Gateway spec |
| `V4_CFG_VIYA_HTTPROUTE_NAME` | `sas-viya-httproute` | No | Name of the HTTPRoute resource |
| `V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE` | `null` | **Yes** (when enabled) | Backend Viya service name for the HTTPRoute |
| `V4_CFG_VIYA_HTTPROUTE_BACKEND_PORT` | `80` | No | Backend service port |

### Default Configuration (Gateway API Disabled)

By default, Gateway API is **disabled** for backwards compatibility:
```yaml
# These are the defaults — Contour is used unless explicitly overridden
V4_CFG_INSTALL_GATEWAY_API: false
V4_CFG_INSTALL_ENVOY_GATEWAY: false
V4_CFG_GENERATE_GATEWAY_API_RESOURCES: false
V4_CFG_INGRESS_TYPE: contour
```

### Enable Gateway API in ansible-vars.yaml

Minimal configuration to enable full Gateway API mode:
```yaml
## Disable traditional ingress
V4_CFG_INGRESS_TYPE: none
V4_CFG_INGRESS_MODE: private           # Required on Azure to avoid NSG violations

## Install Gateway API infrastructure (baseline role)
V4_CFG_INSTALL_GATEWAY_API: true
V4_CFG_INSTALL_ENVOY_GATEWAY: true

## Generate Viya Gateway + HTTPRoute resources (vdm role)
V4_CFG_GENERATE_GATEWAY_API_RESOURCES: true
V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE: "sas-logon-app"
V4_CFG_VIYA_HTTPROUTE_BACKEND_PORT: 443

## Hostname
V4_CFG_INGRESS_FQDN: your-fqdn.example.com

## TLS (auto-generated by certframe)
V4_CFG_TLS_MODE: full-stack
V4_CFG_TLS_GENERATOR: openssl
```

## Implementation Details

### Gateway API CRD Installation

The framework downloads the Gateway API manifest from the official `kubernetes-sigs/gateway-api` GitHub releases. Before applying, a Python-based filter strips `ValidatingAdmissionPolicy` and `ValidatingAdmissionPolicyBinding` resources that can block CRD installation when channels are mixed (standard vs. experimental).

**Files:**
- [`roles/baseline/tasks/gateway-api.yaml`](../../roles/baseline/tasks/gateway-api.yaml)

**Install sequence:**
1. Download manifest to temp directory
2. Parse and filter blocking admission policies using Python `yaml.safe_load_all()`
3. Remove existing cluster-scoped admission policies (idempotent)
4. Create `envoy-gateway-system` namespace
5. Create or recreate `envoy-gateway` TLS secret for the controller
6. Apply filtered CRD manifest with `wait: true`

### Envoy Gateway Controller

Envoy Gateway is installed from its official GitHub releases manifest. Because the manifest contains mixed resource types (CRDs, Deployments, Services), the apply step uses `wait: false` and a separate readiness check loop targets only the `Deployment` resource.

After installation, the deployment is force-restarted to ensure the pod picks up the latest `envoy-gateway` TLS secret. A readiness retry loop waits up to 10 minutes (120 retries × 5s) for the pod to become ready. If it times out, pod phases, container states, and namespace events are printed automatically.

**Files:**
- [`roles/baseline/tasks/envoy-gateway.yaml`](../../roles/baseline/tasks/envoy-gateway.yaml)

**Install sequence:**
1. Download Envoy Gateway manifest
2. Apply manifest with `wait: false`
3. Wait for Deployment object creation (30 retries × 2s)
4. Force-restart deployment via annotation to pick up secret changes
5. Wait for `readyReplicas > 0` (120 retries × 5s = 10 minutes)
6. On timeout: collect pod phases, containerStatuses, and namespace events for diagnosis

### GatewayClass Resource

Envoy Gateway does not auto-create a `GatewayClass`. The framework creates one explicitly after the controller is ready and waits for `Accepted=True`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

### Gateway Resource

Generated from Jinja2 template [`roles/vdm/templates/resources/gateway-api-gateway.yaml`](../../roles/vdm/templates/resources/gateway-api-gateway.yaml).

When TLS is enabled (`V4_CFG_TLS_MODE != disabled`), **only the HTTPS listener** is created on port 443. Port 80 is deliberately omitted to prevent public NSG exposure on Azure.

When TLS is disabled, only an HTTP listener is created on port 80.

**Example rendered output (TLS enabled):**
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: sas-viya-gateway
spec:
  gatewayClassName: envoy
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: aksgw.unx.sas.com
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: sas-ingress-certificate
```

### HTTPRoute Resource

Generated from Jinja2 template [`roles/vdm/templates/resources/gateway-api-httproute.yaml`](../../roles/vdm/templates/resources/gateway-api-httproute.yaml).

When TLS is enabled, the route attaches to the `https` listener via `sectionName: https`.

**Example rendered output (TLS enabled):**
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: sas-viya-httproute
spec:
  parentRefs:
  - name: sas-viya-gateway
    sectionName: https
  hostnames:
  - "aksgw.unx.sas.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: sas-logon-app
      port: 443
```

### TLS Termination

TLS is terminated at the Envoy proxy data-plane pod in `envoy-gateway-system`. The Envoy Gateway controller uses two distinct TLS secrets:

| Secret | Namespace | Used By | Contents |
|---|---|---|---|
| `envoy-gateway` | `envoy-gateway-system` | Envoy Gateway controller internal comms | `tls.crt`, `tls.key`, `ca.crt` (Opaque type) |
| `sas-ingress-certificate` | Viya namespace | Envoy proxy data plane for HTTPS termination | `tls.crt`, `tls.key` (kubernetes.io/tls type) |

The `envoy-gateway` secret is always recreated fresh during baseline install. If user cert/key are not provided, a temporary self-signed certificate is generated automatically.

## Azure-Specific Behavior

### Internal Load Balancer (Recommended)

When `V4_CFG_INGRESS_MODE: private` is set and the provider is Azure, the deployment framework patches the Envoy-generated LoadBalancer service with:

```yaml
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

This is intended to cause Azure to provision an internal (VNet-only) IP address instead of a public IP.

The deployment also verifies the resulting Envoy LoadBalancer service IP. If a public IP is detected, the service is deleted and allowed to reconcile again with the internal annotation. If the service still has a public IP after remediation, the playbook fails fast so the deployment does not continue in a non-compliant state.

The patch is applied automatically in [`roles/vdm/tasks/deploy.yaml`](../../roles/vdm/tasks/deploy.yaml) after Viya resources are deployed, by matching services with the naming pattern `envoy-<namespace>-<gateway-name>-*` in the `envoy-gateway-system` namespace.

### NSG Security Policy Compliance

Azure security policy monitors NSG rules for publicly accessible ports. When a LoadBalancer service opens port 80 or 443 publicly, Azure may automatically restrict the rule and send a violation notification.

To remain compliant:
- Use `V4_CFG_INGRESS_MODE: private` at all times on Azure
- Verify after every deployment that no public LoadBalancer exists:
  ```bash
  kubectl get svc -A --field-selector spec.type=LoadBalancer -o wide
  ```
- All `EXTERNAL-IP` values must resolve to private RFC1918 addresses before the deployment is considered successful (e.g., `10.x.x.x`, `172.16-31.x.x`, `192.168.x.x`)
- If a public IP is ever assigned, delete the LB service and redeploy to trigger the internal annotation

## Key Benefits

- **Standard Kubernetes API**: Uses the official Gateway API spec, not vendor-specific annotations
- **TLS at gateway layer**: Certificate termination at the Envoy proxy; backend services use cluster-internal TLS
- **Port 80 never exposed**: When TLS is enabled, only the 443 listener is created in the Gateway spec
- **Azure NSG compliant controls**: Internal LB annotation plus post-deploy verification/remediation prevent silent public LB exposure when `V4_CFG_INGRESS_MODE: private`
- **Backwards compatible**: Existing Contour/nginx deployments are completely unaffected when all feature flags remain `false`
- **Controller isolation**: Envoy Gateway controller and data-plane pods run in their own namespace (`envoy-gateway-system`)
- **Mutual exclusivity enforced**: Contour, ingress-nginx, and Istio are skipped when Envoy Gateway mode is active
- **Diagnostic output on failure**: Readiness timeouts automatically collect and print pod states and namespace events

## Supported TLS Modes

| `V4_CFG_TLS_MODE` | Listener Created | Port | Certificate Required | Notes |
|---|---|---|---|---|
| `full-stack` | HTTPS | 443 | Yes | Recommended for production; end-to-end TLS |
| `front-door` | HTTPS | 443 | Yes | TLS at ingress only, backend traffic unencrypted |
| `ingress-only` | HTTPS | 443 | Yes | Minimal TLS scope |
| `disabled` | HTTP | 80 | No | Not recommended for production |

## Usage

### Quick Start - Minimal Configuration

Add the following to your `ansible-vars.yaml` and run a full install with tags `baseline,viya,install`:
```yaml
V4_CFG_INGRESS_TYPE: none
V4_CFG_INGRESS_MODE: private

V4_CFG_INSTALL_GATEWAY_API: true
V4_CFG_INSTALL_ENVOY_GATEWAY: true
V4_CFG_GENERATE_GATEWAY_API_RESOURCES: true

V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE: "sas-logon-app"
V4_CFG_VIYA_HTTPROUTE_BACKEND_PORT: 443

V4_CFG_TLS_MODE: full-stack
V4_CFG_TLS_GENERATOR: openssl
V4_CFG_INGRESS_FQDN: your-fqdn.example.com
```

### Full Azure Private Deployment

```yaml
## Ingress
V4_CFG_INGRESS_TYPE: none
V4_CFG_INGRESS_MODE: private

## Gateway API Infrastructure
V4_CFG_INSTALL_GATEWAY_API: true
V4_CFG_INSTALL_ENVOY_GATEWAY: true

## Gateway API Viya Resources
V4_CFG_GENERATE_GATEWAY_API_RESOURCES: true
V4_CFG_VIYA_GATEWAY_NAME: sas-viya-gateway
V4_CFG_VIYA_GATEWAY_CLASS_NAME: envoy
V4_CFG_VIYA_HTTPROUTE_NAME: sas-viya-httproute
V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE: sas-logon-app
V4_CFG_VIYA_HTTPROUTE_BACKEND_PORT: 443

## TLS
V4_CFG_TLS_MODE: full-stack
V4_CFG_TLS_GENERATOR: openssl
V4_CFG_TLS_TRUSTED_CA_CERTS: /data/certs/trusted_certs

## Hostname
V4_CFG_INGRESS_FQDN: aksgw.unx.sas.com
V4_CFG_BASE_DOMAIN: viya4.aksgw.unx.sas.com
```

### Advanced Configuration

**Using customer-provided certificates instead of auto-generated ones:**
```yaml
V4_CFG_TLS_GENERATOR: openssl
V4_CFG_TLS_CERT: /data/certs/viya4.crt
V4_CFG_TLS_KEY: /data/certs/viya4.key
```

**Changing Gateway API version or CRD channel:**
```yaml
GATEWAY_API_VERSION: v1.5.0
GATEWAY_API_NAMESPACE_LABEL_MODE: standard   # or: experimental
ENVOY_GATEWAY_VERSION: v1.8.0
ENVOY_GATEWAY_GATEWAYCLASS_NAME: envoy
```

**Disabling individual Gateway API features while keeping infrastructure:**
```yaml
V4_CFG_INSTALL_GATEWAY_API: true
V4_CFG_INSTALL_ENVOY_GATEWAY: true
V4_CFG_GENERATE_GATEWAY_API_RESOURCES: false   # Do not generate Gateway/HTTPRoute yet
```

See [examples/ansible-vars.yaml](../../examples/ansible-vars.yaml) for a complete reference configuration.

## Validation

### Comprehensive Validation Sequence

```bash
# 1. Verify Gateway API CRDs are installed
kubectl get crds | grep gateway.networking.k8s.io | wc -l
# Expect: 6 or more CRDs

# 2. Verify Envoy Gateway controller is running
kubectl get pods -n envoy-gateway-system
kubectl logs -n envoy-gateway-system deploy/envoy-gateway --tail=50

# 3. Verify GatewayClass is accepted
kubectl get gatewayclass
# Expect: ACCEPTED = True

# 4. Verify Gateway listener is programmed
kubectl get gateway -n viya4 -o wide
kubectl describe gateway sas-viya-gateway -n viya4
# Expect: PROGRAMMED = True
# Expect listener conditions: Accepted=True, ResolvedRefs=True, Programmed=True

# 5. Verify HTTPRoute is attached
kubectl get httproute -n viya4 -o wide
# Expect: PARENT shows sas-viya-gateway, attached routes > 0

# 6. Verify TLS secret exists in Viya namespace
kubectl get secret sas-ingress-certificate -n viya4

# 7. Verify no public LoadBalancer (Azure)
kubectl get svc -A --field-selector spec.type=LoadBalancer -o wide
# All EXTERNAL-IPs must be private addresses if V4_CFG_INGRESS_MODE=private

# 8. Test endpoint connectivity
curl -vkI https://your-fqdn.example.com/SASLogon
# Expect: HTTP 200 or 302 (redirect is normal for SASLogon)
```

### Expected Healthy State

```
GatewayClass:
  NAME                  CONTROLLER                                      ACCEPTED   AGE
  envoy                gateway.envoyproxy.io/gatewayclass-controller   True       5m

Gateway:
  NAMESPACE   NAME               CLASS                 ADDRESS       PROGRAMMED   AGE
  viya4       sas-viya-gateway   envoy                10.x.x.x      True         4m

HTTPRoute:
  NAMESPACE   NAME                 HOSTNAMES               AGE
  viya4       sas-viya-httproute   ["aksgw.unx.sas.com"]   4m

Pods (envoy-gateway-system):
  NAME                                                 READY   STATUS
  envoy-gateway-xxxxx                                  1/1     Running
  envoy-viya4-sas-viya-gateway-xxxxx-xxxxx             2/2     Running
```

## Multi-Service Routing

### Current Single-Route Model

The default implementation generates one `HTTPRoute` with a `PathPrefix: /` rule pointing to a single backend service. This is sufficient for validating a specific Viya endpoint but does not cover all Viya application paths.

With a single catch-all route:
- All traffic to the FQDN is forwarded to one backend service
- Services like SAS Studio, SAS Visual Analytics, SAS Drive etc. are not individually routed
- The backend service only serves requests it understands

### Full Viya Service Routing via Ingress Conversion

Viya deploys standard Kubernetes `Ingress` resources for each service. These can be converted to `HTTPRoute` resources to achieve full application coverage:

```bash
# Step 1: Remove the default single-backend catch-all route
kubectl delete httproute sas-viya-httproute -n viya4 --ignore-not-found

# Step 2: Discover all Ingress-defined backend services
kubectl -n viya4 get ingress \
  -o jsonpath='{range .items[*].spec.rules[*].http.paths[*]}{.backend.service.name}{"\n"}{end}' \
  | sort -u

# Step 3: Generate one HTTPRoute per Ingress backend (requires jq)
kubectl get ingress -n viya4 -o json | jq -c '
  .items[] as $ing
  | ($ing.spec.rules // [])[]
  | {
      apiVersion: "gateway.networking.k8s.io/v1",
      kind: "HTTPRoute",
      metadata: {
        name: ("hr-" + $ing.metadata.name),
        namespace: $ing.metadata.namespace
      },
      spec: {
        parentRefs: [{ name: "sas-viya-gateway", sectionName: "https" }],
        hostnames: (if .host == null then [] else [.host] end),
        rules: [
          (.http.paths[] | {
            matches: [{ path: { type: "PathPrefix", value: (.path // "/") } }],
            backendRefs: [{
              name: .backend.service.name,
              port: (.backend.service.port.number // 443)
            }]
          })
        ]
      }
    }' | jq -s '.[]' | kubectl apply -f -

# Step 4: Restart controller to reconcile all new routes
kubectl rollout restart deploy/envoy-gateway -n envoy-gateway-system

# Step 5: Verify
kubectl get httproute -n viya4 | wc -l
kubectl get gateway -n viya4 -o wide
```

**Important**: When `V4_CFG_GENERATE_GATEWAY_API_RESOURCES: true`, the playbook will recreate `sas-viya-httproute` on the next run. Set it to `false` if you are managing routes manually after the initial deployment.

## Troubleshooting

### Gateway Programmed=False

**Symptom:** `kubectl get gateway -n viya4` shows `PROGRAMMED=False`

**Diagnosis:**
```bash
kubectl describe gateway sas-viya-gateway -n viya4
# Look at: Status > Listeners > Conditions
```

**Common causes and fixes:**

| Listener Condition | Reason | Fix |
|---|---|---|
| `ResolvedRefs=False` / `InvalidCertificateRef` | `sas-ingress-certificate` secret missing | `kubectl create secret tls sas-ingress-certificate --cert=<crt> --key=<key> -n viya4` |
| `Programmed=False` / `NoResources` | Envoy proxy pods not ready | See [Envoy Proxy 1/2 Containers Ready](#envoy-proxy-12-containers-ready) |
| `Accepted=False` | Invalid or missing GatewayClass name | Verify `kubectl get gatewayclass` shows `Accepted=True` for `envoy` |
| `AddressNotAssigned` | No LoadBalancer IP provisioned yet | Wait 2-3 minutes; check Azure LB provisioning in portal |

### Envoy Proxy 1/2 Containers Ready

**Symptom:** Proxy pod shows `1/2` or `0/2` in `READY` column

**Diagnosis:**
```bash
kubectl describe pod -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=sas-viya-gateway,\
gateway.envoyproxy.io/owning-gateway-namespace=viya4

kubectl get events -n envoy-gateway-system \
  --sort-by=.metadata.creationTimestamp | tail -n 30

kubectl logs -n envoy-gateway-system deploy/envoy-gateway --tail=200 | grep -i error
```

**Common causes and fixes:**

| Symptom in logs/events | Cause | Fix |
|---|---|---|
| `service viya4/sas-gateway not found` | `V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE` is wrong | Patch HTTPRoute to a real service name (e.g., `sas-logon-app`) |
| `ImagePullBackOff` | Cannot pull `docker.io/envoyproxy/envoy:distroless-v1.x.x` | Check network/proxy access to Docker Hub |
| Container `shutdown-manager` not ready | Probe configuration mismatch | Restart controller: `kubectl rollout restart deploy/envoy-gateway -n envoy-gateway-system` |

**Fix for wrong backend service:**
```bash
# Find real services
kubectl get svc -n viya4 | grep -i logon

# Patch HTTPRoute
kubectl patch httproute sas-viya-httproute -n viya4 --type merge \
  -p '{"spec":{"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}],"backendRefs":[{"name":"sas-logon-app","port":443}]}]}}'

kubectl rollout restart deploy/envoy-gateway -n envoy-gateway-system
```

### Security Policy Violation (NSG 443/80)

**Symptom:** Azure security notification about publicly exposed port 443 or 80

**Root cause:** LoadBalancer service was created without the internal annotation

**Fix:**
1. Set `V4_CFG_INGRESS_MODE: private` in `ansible-vars.yaml`
2. Delete the Envoy-generated LB service to force recreation:
   ```bash
   kubectl delete svc -n envoy-gateway-system \
     $(kubectl get svc -n envoy-gateway-system \
       -o name | grep envoy-viya4)
   ```
3. Rerun deployment so the LB service is recreated with the internal annotation

**Verify the fix:**
```bash
kubectl get svc -n envoy-gateway-system -o yaml | grep -A3 azure-load-balancer
# Should show: service.beta.kubernetes.io/azure-load-balancer-internal: "true"

kubectl get svc -n envoy-gateway-system -o wide
# EXTERNAL-IP should be a private (10.x.x.x) address
```

### HTTPRoute Not Accepting Traffic

**Symptom:** Gateway is `Programmed=True` and proxy is `2/2` but requests return HTTP 500 or connection is refused

**Diagnosis:**
```bash
kubectl logs -n envoy-gateway-system deploy/envoy-gateway --tail=200
kubectl describe httproute sas-viya-httproute -n viya4
```

**Common causes:**

| Error | Cause | Fix |
|---|---|---|
| `setting 500 direct response` | Backend service/port mismatch or service not found | Verify service exists and port is correct |
| `connection refused` on `curl` | TCP not reaching Envoy pod | Check LB IP is correct in DNS |
| `SSL handshake failed` | Cert hostname mismatch | Verify `V4_CFG_INGRESS_FQDN` matches certificate CN/SAN |
| HTTP 200 but wrong app | Catch-all route sends to wrong service | Set correct `V4_CFG_VIYA_HTTPROUTE_BACKEND_SERVICE` or use multi-service routing |

## Known Limitations

1. **Single HTTPRoute for all paths**: The deployment generates one catch-all `HTTPRoute` pointing to one backend service. Full Viya application routing requires manually converting existing Ingress rules or a future automated multi-route generation feature. See [Multi-Service Routing](#multi-service-routing).

2. **`sas-ingress-certificate` timing**: When using `V4_CFG_TLS_GENERATOR: openssl` without customer certs, the SAS certframe job creates the secret during Viya pod startup. If the Gateway is created before the job completes, the listener will initially show `InvalidCertificateRef` and then reconcile automatically once the secret appears. No manual intervention is needed.

3. **Contour co-existence not supported**: Contour and Envoy Gateway cannot run in the same deployment for the same namespace. If Contour is already installed, remove it before switching to Gateway API mode by running a baseline uninstall.

4. **Azure LB convergence timing**: During provisioning, Azure may temporarily surface a non-final LoadBalancer address. The deployment now enforces private mode by patching, verifying, and remediating Envoy LB services, and fails if it cannot converge to private RFC1918 addressing.

5. **No per-service HTTPRoute automation**: There is no current automated path to generate one `HTTPRoute` per Viya service during deployment. Multi-service conversion must be performed manually post-deploy using the Ingress conversion script in [Multi-Service Routing](#multi-service-routing).

6. **DNS must point to Gateway IP**: DNS for `V4_CFG_INGRESS_FQDN` must be updated to point to the Envoy Gateway LoadBalancer IP. When `V4_CFG_INGRESS_MODE: private`, this IP is a private VNet address and DNS resolution must work from within the allowed network.
