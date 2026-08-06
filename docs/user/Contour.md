# Contour Ingress Controller

Contour is an open-source ingress controller that uses Envoy proxy as its data plane. It is the default ingress controller for SAS Viya platform deployments starting with the 2026.03 cadence release. For more information, see the [official Contour documentation](https://projectcontour.io/).

## What viya4-deployment Does with Contour

When `V4_CFG_INGRESS_TYPE: contour` is set in your ansible-vars.yaml file, viya4-deployment performs the following tasks:

### Baseline Deployment

- Deploys Contour to the `projectcontour` namespace via Helm
- Configures Contour with compression settings and resource limits
- Applies provider-specific settings (AWS NLB, Azure health probes, etc.)
- Configures multi-zone high availability when `V4_CFG_MULTI_ZONE_ENABLED: true`
- Adds Envoy tolerations for nodes with `workload.sas.com/class` taints

### SAS Viya Platform Integration

- Adds `sas-bases/overlays/network/projectcontour.io` overlay to your kustomization.yaml
- Applies TLS components when configured:
  - `sas-bases/components/security/network/projectcontour.io/httpproxy/full-stack-tls`
  - `sas-bases/components/security/network/projectcontour.io/httpproxy/front-door-tls`

These overlays configure SAS Viya services to use HTTPProxy custom resources instead of standard Ingress resources.

**Important**: The SAS Viya platform overlays only affect your deployment namespace and do not modify Contour installations in other namespaces.

## Deployment Scenarios

Set `V4_CFG_INGRESS_TYPE: contour` and run the playbook normally. viya4-deployment handles all Contour deployment and configuration.

## Configuration

For configuration details, see [CONFIG-VARS.md](../CONFIG-VARS.md#contour).

### Multi-Zone High Availability

```yaml
V4_CFG_MULTI_ZONE_ENABLED: true              # Enables multi-zone for SAS Viya and Contour
V4_CFG_MULTI_ZONE_CONTOUR_ENABLED: true      # Defaults to true when multi-zone is enabled
```

This automatically detects availability zones and configures Contour controller replicas, topology spread constraints, and pod anti-affinity.

## Additional Resources

- [CONFIG-VARS.md](../CONFIG-VARS.md#contour) - Configuration reference
- [NetworkingConsiderations.md](./NetworkingConsiderations.md) - Networking requirements
- [MultiZoneDistribution.md](./MultiZoneDistribution.md) - Multi-zone deployment details
- [Official Contour Documentation](https://projectcontour.io/)
