# Multi-Zone StatefulSet Distribution - Implementation Guide

## Table of Contents

- [Multi-Zone StatefulSet Distribution - Implementation Guide](#multi-zone-statefulset-distribution---implementation-guide)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Important Limitations](#important-limitations)
    - [Internal PostgreSQL Not Supported](#internal-postgresql-not-supported)
  - [Configuration Variables](#configuration-variables)
    - [Core Settings (roles/vdm/defaults/main.yaml)](#core-settings-rolesvdmdefaultsmainyaml)
    - [Default Configuration (Multi-Zone Disabled)](#default-configuration-multi-zone-disabled)
    - [Enable Multi-Zone Distribution in ansible-vars.yaml](#enable-multi-zone-distribution-in-ansible-varsyaml)
  - [Implementation Details](#implementation-details)
    - [Topology Spread Constraints (Balanced Approach)](#topology-spread-constraints-balanced-approach)
    - [Node Affinity (Nodepool Restriction)](#node-affinity-nodepool-restriction)
    - [Preferred Pod Anti-Affinity](#preferred-pod-anti-affinity)
  - [Key Benefits](#key-benefits)
  - [Supported StatefulSets](#supported-statefulsets)
    - [Implementation Notes](#implementation-notes)
  - [Stateless Services Zone Distribution](#stateless-services-zone-distribution)
    - [Configuration](#configuration)
    - [Implementation Details](#implementation-details-1)
    - [Benefits](#benefits)
  - [Usage](#usage)
    - [Quick Start - Enable Multi-Zone](#quick-start---enable-multi-zone)
    - [Advanced Configuration](#advanced-configuration)
    - [Sample Configuration Files](#sample-configuration-files)
  - [Nodepool Requirements](#nodepool-requirements)
    - [Comprehensive Validation Report](#comprehensive-validation-report)
  - [Chaos Testing \& Validation](#chaos-testing--validation)
    - [Zone Failure Simulation Results](#zone-failure-simulation-results)
    - [Known Limitation (By Design)](#known-limitation-by-design)
    - [Alternative Constraint Options](#alternative-constraint-options)

## Overview
This implementation provides balanced multi-zone pod distribution for StatefulSets in AKS, EKS, and GKE clusters to prevent quorum loss during zone failures while ensuring reliable scheduling.

**Note**: As of DaC 9.7.0, multi-zone distribution is **disabled by default** to maintain backwards compatibility. Enable it explicitly when your cluster has proper multi-zone setup.

## Important Limitations

### Internal PostgreSQL Not Supported
**An internal SAS PostgreSQL server is NOT supported for a multi-zone deployment at this time.**

When deploying SAS Viya in a multi-zone configuration:
- **DO NOT use** `V4_CFG_POSTGRES_SERVERS.default.internal: true`
- **MUST use** external PostgreSQL service from your cloud provider:
  - **Azure**: PostgreSQL Flexible Server with `--high-availability ZoneRedundant`
  - **AWS**: RDS for PostgreSQL with Multi-AZ deployment
  - **GCP**: Cloud SQL for PostgreSQL with High Availability configuration

**Why this limitation exists:**
- Complex storage requirements for multi-zone persistent volumes
- Crunchy PostgreSQL operator limitations in zone-failure scenarios
- Data consistency and backup/restore complications across zones
- Not fully validated/tested by SAS for production use

**Configuration Example for Multi-Zone:**
```yaml
# Required: Use external PostgreSQL
V4_CFG_POSTGRES_SERVERS:
  default:
    internal: false  # Required for multi-zone
    fqdn: your-postgres-server.postgres.database.azure.com
    admin: pgadmin
    password: your-password
    ssl_enforcement_enabled: true
    database: postgres
```

For zone redundancy configuration of external PostgreSQL, see the [PostgreSQL Documentation](PostgreSQL.md).

## Configuration Variables

### Core Settings (roles/vdm/defaults/main.yaml)
**Important**: `V4_CFG_MULTI_ZONE_ENABLED` is the master switch - all individual service flags below are ignored unless the master switch is `true`.

- `V4_CFG_MULTI_ZONE_ENABLED`: Master switch for multi-zone distribution (default: **false**)
- `V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED`: RabbitMQ distribution control (default: true)
- `V4_CFG_MULTI_ZONE_CONSUL_ENABLED`: Consul distribution control (default: true)
- `V4_CFG_MULTI_ZONE_REDIS_ENABLED`: Redis distribution control (default: true)
- `V4_CFG_MULTI_ZONE_OPENDISTRO_ENABLED`: OpenDistro/OpenSearch distribution control (default: true)
- `V4_CFG_MULTI_ZONE_WORKLOAD_ORCHESTRATOR_ENABLED`: Workload Orchestrator distribution control (default: true)
- `V4_CFG_MULTI_ZONE_DATA_AGENT_ENABLED`: Data Agent Server distribution control (default: true)
- `V4_CFG_MULTI_ZONE_STATELESS_ENABLED`: Stateless services (Deployments) distribution control (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_RESTRICTION`: Restrict to stateful nodepools (default: **false**)
- `V4_CFG_STATEFUL_NODEPOOL_LABEL`: Label for stateful nodepool identification (default: "workload.sas.com/class")
- `V4_CFG_SINGLE_ZONE_FALLBACK`: Apply relaxed constraints for single-zone clusters (default: true)

### Default Configuration (Multi-Zone Disabled)
By default, multi-zone distribution is **disabled** for backwards compatibility:
```yaml
# These are the defaults - no configuration needed for single-zone deployments
V4_CFG_MULTI_ZONE_ENABLED: false
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: false
```

### Enable Multi-Zone Distribution in ansible-vars.yaml
To enable multi-zone distribution, add this to your ansible-vars.yaml:
```yaml
# Enable multi-zone distribution
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
V4_CFG_STATEFUL_NODEPOOL_LABEL: "workload.sas.com/class"

# Enable HA for stateless services
V4_CFG_HA_ENABLED: true

# REQUIRED: Use external PostgreSQL for multi-zone deployments
V4_CFG_POSTGRES_SERVERS:
  default:
    internal: false  # Must be false for multi-zone
    fqdn: your-postgres-server.postgres.database.azure.com
    admin: pgadmin
    password: "YourPassword"
    ssl_enforcement_enabled: true
    database: postgres

# Optional: Fine-tune individual services (all default to true when multi-zone enabled)
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: true
V4_CFG_MULTI_ZONE_CONSUL_ENABLED: true
V4_CFG_MULTI_ZONE_REDIS_ENABLED: true
V4_CFG_MULTI_ZONE_OPENDISTRO_ENABLED: true
V4_CFG_MULTI_ZONE_WORKLOAD_ORCHESTRATOR_ENABLED: true
V4_CFG_MULTI_ZONE_DATA_AGENT_ENABLED: true
V4_CFG_MULTI_ZONE_STATELESS_ENABLED: true
V4_CFG_SINGLE_ZONE_FALLBACK: true
```

## Implementation Details

### Topology Spread Constraints (Balanced Approach)
- **Zone Distribution**: `maxSkew: 1` on `topology.kubernetes.io/zone` with `DoNotSchedule`
  - **Strict enforcement** at zone level to prevent concentration
  - Ensures StatefulSet replicas are distributed across availability zones
  - Primary protection against zone failures (PSCLOUD-64 resolution)
  
- **Node Distribution**: `maxSkew: 1` on `kubernetes.io/hostname` with `ScheduleAnyway`
  - **Best-effort spreading** at node level without blocking scheduling
  - Kubernetes attempts to spread pods across different nodes when possible
  - Will not prevent pod scheduling if perfect node balance cannot be achieved
  - Prevents scheduling deadlock when combined with zone-level constraints

### Node Affinity (Nodepool Restriction)
- **Required Node Affinity**: Configurable nodepool label restriction (default: `workload.sas.com/class=stateful`)
  - Ensures StatefulSets only schedule on nodes with the specified stateful nodepool label
  - Prevents cross-nodepool scheduling that could compromise zone isolation
  - Supports both modern (`workload.sas.com/class`) and legacy (`agentpool`) label formats

### Preferred Pod Anti-Affinity
- **Host Distribution**: Preferred anti-affinity for `kubernetes.io/hostname`
  - Attempts to spread pods across different nodes when possible
  - Uses weight: 100 preference (not required)

## Key Benefits

- **Zone Failure Protection**: Distributes StatefulSet replicas across availability zones
- **Nodepool Isolation**: Prevents StatefulSets from mixing with stateless workloads
- **Quorum Safety**: Single zone failure won't compromise StatefulSet availability
- **Reliable Scheduling**: Balanced constraints allow successful deployment
- **Multi-Cloud Support**: Works with AKS, EKS, and GKE
- **Comprehensive Coverage**: Supports 7 critical StatefulSet workloads
- **Automatic Detection**: Auto-detects multi-zone clusters and applies appropriate constraints
- **Single-Zone Fallback**: Gracefully handles single-zone deployments with relaxed constraints

## Supported StatefulSets

This implementation provides multi-zone distribution for the following StatefulSet workloads:

**Note**: Internal PostgreSQL is NOT supported for multi-zone deployments. You must use external PostgreSQL with your cloud provider's zone-redundant HA service.

| # | StatefulSet Name | Description | Transformer Target |
|---|------------------|-------------|--------------------|
| 1 | sas-rabbitmq-server | Message queue service | StatefulSet (direct) |
| 2 | sas-consul-server | Service discovery and configuration | StatefulSet (direct) |
| 3 | sas-redis-server | Caching and session store | StatefulSet (direct) |
| 4 | sas-opendistro-default | Search and logging (OpenSearch) | OpenDistroCluster CR (operator-managed) |
| 5 | sas-workload-orchestrator | Job scheduling and orchestration | StatefulSet (direct) |
| 6 | sas-data-agent-server-colocated | Data agent services | StatefulSet (direct) |

### Implementation Notes

**OpenDistro (sas-opendistro-default)**:
- Deployed via Custom Resource: `OpenDistroCluster` (API: `opendistro.sas.com/v1alpha1`)
- Transformer patches the CR at `/spec/template/spec/topologySpreadConstraints`
- The `sas-opendistro-operator` watches the CR and creates the StatefulSet with constraints
- StatefulSet name is `sas-opendistro-default` (not directly patched)

**Important - OpenDistro Multi-Nodeset Configuration**:
When using custom multi-nodeset topology (separate `sas-opendistro-custom-data` and `sas-opendistro-custom-master` StatefulSets):
- **CRD Limitation**: The OpenDistroCluster CRD only supports a **global template** at `/spec/template` - there is no per-nodeset template override capability
- **Global Balancing Approach**: The transformer uses a cluster-wide label selector (`opendistro.sas.com/cluster-name: sas-opendistro`) that matches **all OpenDistro pods** (both data and master)
- **Expected Behavior**: With `maxSkew: 1` and 3 zones, the scheduler balances all 6 pods (3 data + 3 master) as a single group:
  - Allows up to 2 pods per zone (6 pods ÷ 3 zones = 2, skew = 1)
  - Ensures cluster-wide zone distribution: each zone gets 2 OpenDistro pods total
  - **Does not guarantee** 1 data + 1 master per zone - distribution could vary (e.g., zone-a: 2 data + 0 master, zone-b: 1 data + 1 master, zone-c: 0 data + 2 master)
- **Trade-off**: This approach provides zone-level fault tolerance for the OpenDistro cluster as a whole, though individual nodeset distribution may be uneven across zones
- **Acceptable for Production**: The Elasticsearch/OpenSearch cluster remains resilient to zone failures as long as master quorum (2 of 3) and data availability are maintained across the remaining zones

**Direct StatefulSet Transformers**:
- RabbitMQ, Consul, Redis, Workload Orchestrator, Data Agent
- Transformers directly patch StatefulSet resources
- Use strict zone enforcement (`DoNotSchedule`) with soft hostname spreading (`ScheduleAnyway`)

## Stateless Services Zone Distribution

In addition to StatefulSet zone distribution, DaC now supports **multi-zone distribution for stateless services (Deployments)** when combined with HA mode.

### Configuration

To enable zone distribution for stateless services:
```yaml
# Enable both HA and multi-zone distribution
V4_CFG_HA_ENABLED: true
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_MULTI_ZONE_STATELESS_ENABLED: true  # Default: true
```

**Requirements**:
- `V4_CFG_HA_ENABLED: true` must be set (to ensure multiple replicas exist)
- `V4_CFG_MULTI_ZONE_ENABLED: true` must be set (master switch)

### Implementation Details

**Topology Spread Constraints for Stateless Services**:
- **Zone Distribution**: `maxSkew: 1` on `topology.kubernetes.io/zone` with `ScheduleAnyway`
  - **Best-effort enforcement** - encourages zone distribution without blocking scheduling
  - More relaxed than StatefulSet constraints to maintain flexibility
  
- **Node Distribution**: `maxSkew: 1` on `kubernetes.io/hostname` with `ScheduleAnyway`
  - **Best-effort spreading** at node level
  - Kubernetes attempts to spread pods across different nodes when possible

**Pod Anti-Affinity**:
- Preferred anti-affinity for both zone and node spreading
- Weight: 100 for zone-level preference

**Key Differences from StatefulSet Distribution**:
- Uses `ScheduleAnyway` instead of `DoNotSchedule` for more flexibility
- No nodepool restrictions (stateless services can run on any nodepool)
- Focuses on best-effort distribution rather than strict enforcement
- Designed to work with HA replicas (typically 2-3 per service)

### Benefits
- Enhanced resilience to zone failures for stateless microservices
- Improved load distribution across availability zones
- Maintains scheduling flexibility for dynamic scaling
- Complements StatefulSet zone distribution for complete multi-zone coverage

## Usage

### Quick Start - Enable Multi-Zone
Multi-zone distribution is **disabled by default** for backwards compatibility. To enable it, add this minimal configuration to your ansible-vars.yaml:
```yaml
# Enable multi-zone distribution (disabled by default)
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true

# Also enable HA for stateless service zone distribution
V4_CFG_HA_ENABLED: true
V4_CFG_MULTI_ZONE_STATELESS_ENABLED: true
```

### Advanced Configuration
For custom nodepool labels or selective service control:
```yaml
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
V4_CFG_STATEFUL_NODEPOOL_LABEL: "workload.sas.com/class"  # or "agentpool" for legacy

# Disable specific services if needed
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: false  # Keep RabbitMQ in single zone
```

### Sample Configuration Files
See:
- [examples/ansible-vars-multi-zone.yaml](../../examples/ansible-vars-multi-zone.yaml) - Complete multi-zone configuration
- [examples/ansible-vars.yaml](../../examples/ansible-vars.yaml) - Standard single-zone deployment (default)

## Nodepool Requirements

Ensure your stateful nodepool is labeled correctly. The default label is:
```bash
kubectl label nodes <stateful-node> workload.sas.com/class=stateful
```

You can customize the nodepool label using:
```yaml
V4_CFG_STATEFUL_NODEPOOL_LABEL: "workload.sas.com/class"
```

For legacy deployments using `agentpool` label:
```bash
kubectl label nodes <stateful-node> agentpool=stateful
```

### Comprehensive Validation Report
```bash
echo "=== Validation Report ==="
for sts in sas-rabbitmq-server sas-consul-server sas-redis-server sas-workload-orchestrator sas-data-agent-server-colocated sas-opendistro-default; do
  count=$(kubectl get statefulset $sts -n <namespace> -o jsonpath='{.spec.template.spec.topologySpreadConstraints}' 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
  if [ "$count" == "2" ]; then
    echo "  ✓ $sts: $count constraints"
  else
    echo "  ✗ $sts: $count constraints (expected 2)"
  fi
done
```

## Chaos Testing & Validation

### Zone Failure Simulation Results

Chaos testing was performed to validate multi-zone resilience by cordoning all nodes in a zone and deleting StatefulSet pods to simulate complete zone failure.

**Test Scenario**:
- Cordoned all stateful nodes in single zone
- Deleted pods (RabbitMQ, Consul, Redis) that were running on the cordoned zone
- Monitored rescheduling behavior and constraint enforcement

**Observed Behavior**:
- Deleted pods entered `Pending` state and could not reschedule to remaining zones
- Topology constraints prevented scheduling that would violate `maxSkew: 1`
- With current distribution 0-1-1 (after zone-1 failure), scheduling to either remaining zone would create 0-2-1 or 0-1-2 distribution (skew = 2), which violates the constraint
- Pods remained `Pending` until the failed zone was recovered (node uncordoned)
- Once zone became available, pods automatically rescheduled and restored balanced distribution

**Validation Result**: Topology constraints working as designed

**Production Deployment Note**:
The hostname-level constraint uses `ScheduleAnyway` (best-effort) to ensure StatefulSets
can schedule successfully even when perfect node-level balance is not achievable. This
prevents scheduling deadlock while maintaining strict zone-level protection. Zone-level
distribution remains strictly enforced with `DoNotSchedule` to prevent concentration.

### Known Limitation (By Design)

**Complete Zone Failure Behavior**:
- When an entire availability zone becomes unavailable (all nodes cordoned/failed), affected StatefulSet pods **cannot reschedule** to remaining zones
- Pods remain in `Pending` state until the failed zone recovers
- This is the intended behavior with strict zone-level constraint: `maxSkew: 1` + `whenUnsatisfiable: DoNotSchedule`

**Why This is Acceptable**:
1. **Primary Goal Achieved**: Prevents cross-nodepool pods from concentrating in a single zone during normal operations
2. **Rare Scenario**: Complete zone failures are uncommon (Azure/AWS/GCP multi-zone SLA > 99.99%)
3. **Planned Maintenance**: Production zone maintenance is typically planned, allowing for graceful pod draining
4. **Trade-off Decision**: Temporary unavailability during zone outage vs. chronic concentration risk in normal operations
5. **Production Safety**: Hostname-level constraint uses `ScheduleAnyway` to prevent scheduling issues during normal operations while zone-level remains strict

**Recovery**:
Once the zone becomes available again, pods automatically reschedule and rebalance:
```bash
kubectl uncordon <zone-nodes>
# Pods reschedule automatically to restore balanced distribution
```

### Alternative Constraint Options

If different scheduling behavior is required, consider:

**Option A: Strict Hostname Enforcement**
```yaml
whenUnsatisfiable: DoNotSchedule  # For both zone AND hostname
```
- Warning: May cause scheduling deadlock in constrained environments
- Only recommended for clusters with abundant stateful node capacity

**Option B: Relax Zone Constraint**
```yaml
# Zone-level
whenUnsatisfiable: ScheduleAnyway  # Allows zone concentration

# Hostname-level  
whenUnsatisfiable: ScheduleAnyway  # Current: best-effort spreading
```
- Warning: Weakens primary PSCLOUD-64 protection
- Not recommended for production multi-zone deployments

**Option C: Increase Zone maxSkew**
```yaml
maxSkew: 2  # Allows more imbalanced zone distribution
```
- Warning: Permits concentration (e.g., 0-2-1 or 1-3-2 distribution)
- Reduces protection against zone failures

**Current Implementation (Recommended)**: Uses strict zone enforcement (`DoNotSchedule`, `maxSkew: 1`) with best-effort hostname spreading (`ScheduleAnyway`, `maxSkew: 1`) to balance zone protection with reliable scheduling.
