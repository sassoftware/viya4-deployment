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

## Important Notes

- Do not combine this mode with traditional ingress controllers in the same run.
- If a route backend service does not exist, Envoy Gateway logs a route processing error and returns HTTP 500 for that specific route.


## Additional Resources

- [CONFIG-VARS.md](../CONFIG-VARS.md#ingress)
- [NetworkingConsiderations.md](./NetworkingConsiderations.md)
- [Official Gateway API documentation](https://gateway-api.sigs.k8s.io/)
- [Official Envoy Gateway documentation](https://gateway.envoyproxy.io/)
