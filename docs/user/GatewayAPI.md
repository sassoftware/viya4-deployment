# Gateway API + Envoy Gateway

Gateway API with Envoy Gateway is supported as an ingress option for SAS Viya deployments. This mode uses Gateway API resources (`GatewayClass`, `Gateway`, `ListenerSet`, `HTTPRoute`) instead of traditional `Ingress`/Contour HTTPProxy paths.

## What viya4-deployment Does

When `V4_CFG_INGRESS_TYPE: envoy-gateway` is set, viya4-deployment configures Gateway API and Envoy Gateway with shared defaults.

### Baseline Behavior

- Installs Gateway API CRDs
- Installs Envoy Gateway controller in `envoy-gateway-system`
- Creates/uses GatewayClass `envoy`
- Creates a shared bootstrap Gateway (`k8s-gw`) in `envoy-gateway-system`
- Applies provider-specific Envoy service settings (for example, Azure internal LB annotation when private ingress is used)

### SAS Viya Integration

- Enables Gateway API resource generation by default
- In `envoy-gateway` mode, uses a namespace-local `ListenerSet` (`{{ NAMESPACE }}-listeners`) attached to the shared bootstrap Gateway
- Generates HTTPRoute resources for Viya traffic (single route, explicit multi-route list, or auto-discovered routes)
- Uses `sas-ingress-certificate` for HTTPS listener termination

## Auto-Defaults in Envoy Mode

When `V4_CFG_INGRESS_TYPE: envoy-gateway` is set, these feature flags are auto-enabled unless explicitly overridden in `ansible-vars.yaml`:

- `V4_CFG_INSTALL_GATEWAY_API`
- `V4_CFG_INSTALL_ENVOY_GATEWAY`
- `V4_CFG_GENERATE_GATEWAY_API_RESOURCES`

The following values are also defaulted unless you override them:

- `ENVOY_GATEWAY_GATEWAYCLASS_NAME: envoy`
- `V4_CFG_VIYA_GATEWAY_CLASS_NAME: envoy`
- `V4_CFG_BASELINE_CREATE_BOOTSTRAP_GATEWAY: true`
- `V4_CFG_BASELINE_GATEWAY_NAMESPACE: envoy-gateway-system`
- `V4_CFG_BASELINE_GATEWAY_NAME: k8s-gw`
- `V4_CFG_BASELINE_GATEWAY_ENABLE_HTTP_LISTENER: true`
- `V4_CFG_BASELINE_GATEWAY_TLS_SECRET_NAME: gateway-secret`

## Minimal Configuration

```yaml
V4_CFG_INGRESS_TYPE: envoy-gateway
V4_CFG_INGRESS_MODE: private
V4_CFG_TLS_MODE: full-stack
V4_CFG_INGRESS_FQDN: your-fqdn.example.com
```

Optional overrides can still be set explicitly in `ansible-vars.yaml`.

## IPv6 / Dual-Stack Support

Setting `V4_CFG_ENABLE_IPV6: true` applies provider-specific dual-stack configuration to the Envoy Gateway-managed Service and proxy, mirroring `ingress-nginx`/`contour`, but tailored to how each cloud provider actually implements IPv6 Kubernetes networking:

- **AWS**: EKS IPv6 clusters are single-stack IPv6 internally (one Service CIDR family only); the dual-stack behavior exists only at the external Network Load Balancer, which the AWS Load Balancer Controller fronts with both IPv4 and IPv6 addresses while still targeting IPv6-only backend pods. The EnvoyProxy service annotations configure this NLB (`aws-load-balancer-type: nlb-ip`, `aws-load-balancer-ip-address-type: dualstack`, `aws-load-balancer-nlb-target-type: ip`, `preserve_client_ip.enabled=false`, cross-zone load balancing, and `aws-load-balancer-proxy-protocol: "*"` to recover the real client IP). `EnvoyProxy.spec.ipFamily` is set to `IPv6` (single-stack) to match the cluster's actual Service networking -- setting `DualStack` here fails with `this cluster is not configured for dual-stack services`.
- **Azure**: AKS supports genuine dual-stack Service networking, so `EnvoyProxy.spec.ipFamily` is set to `DualStack`.
- **GCP**: Not supported.
- **All providers**: `EnvoyProxy.spec.ipFamily` defaults to IPv4-only, which otherwise leaves Envoy's internal admin/health-check listener bound only to `0.0.0.0`; on an IPv6/dual-stack cluster this fails the data-plane pod's readiness/liveness probes (Gateway status shows `Programmed: False` / `Envoy replicas unavailable`, and the pod crash-loops). See [envoyproxy/gateway#7600](https://github.com/envoyproxy/gateway/issues/7600).

Requires the underlying cluster to be created with IPv6 networking enabled (see your cloud provider's IaC project).

**Minimum Envoy Gateway version**: `v1.8.2` (the default `ENVOY_GATEWAY_VERSION` is `v1.8.3`). Versions `v1.8.0`/`v1.8.1` reject IPv6 CIDRs in `loadBalancerSourceRanges` ([envoyproxy/gateway#9048](https://github.com/envoyproxy/gateway/issues/9048)), which leaves the baseline `Gateway` stuck with an `Accepted: False` / `InvalidParameters` condition and no data-plane Envoy Deployment/Service ever gets created. If `LOADBALANCER_SOURCE_RANGES` includes any IPv6 CIDRs, make sure `ENVOY_GATEWAY_VERSION` is `v1.8.2` or later.

## Important Notes

- Do not combine this mode with traditional ingress controllers in the same run.
- If a route backend service does not exist, Envoy Gateway logs a route processing error and returns HTTP 500 for that specific route.


## Additional Resources

- [CONFIG-VARS.md](../CONFIG-VARS.md#ingress)
- [NetworkingConsiderations.md](./NetworkingConsiderations.md)
- [Official Gateway API documentation](https://gateway-api.sigs.k8s.io/)
- [Official Envoy Gateway documentation](https://gateway.envoyproxy.io/)
