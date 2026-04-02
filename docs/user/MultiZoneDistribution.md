# Multi-Zone StatefulSet Distribution - Implementation Guide

## Overview
This implementation provides balanced multi-zone pod distribution for StatefulSets in AKS, EKS, and GKE clusters to prevent quorum loss during zone failures while ensuring reliable scheduling.

## Configuration Variables

### Core Settings (roles/vdm/defaults/main.yaml)
- `V4_CFG_MULTI_ZONE_ENABLED`: Master switch for multi-zone distribution (default: true)
- `V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED`: RabbitMQ distribution control (default: true)
- `V4_CFG_MULTI_ZONE_POSTGRES_ENABLED`: PostgreSQL distribution control (default: true)
- `V4_CFG_MULTI_ZONE_CONSUL_ENABLED`: Consul distribution control (default: true)
- `V4_CFG_MULTI_ZONE_REDIS_ENABLED`: Redis distribution control (default: true)
- `V4_CFG_MULTI_ZONE_OPENDISTRO_ENABLED`: OpenDistro/OpenSearch distribution control (default: true)
- `V4_CFG_MULTI_ZONE_WORKLOAD_ORCHESTRATOR_ENABLED`: Workload Orchestrator distribution control (default: true)
- `V4_CFG_MULTI_ZONE_DATA_AGENT_ENABLED`: Data Agent Server distribution control (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_RESTRICTION`: Restrict to stateful nodepools (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_LABEL`: Label for stateful nodepool identification (default: "workload.sas.com/class")
- `V4_CFG_MULTI_ZONE_AUTO_DETECT`: Automatically detect multi-zone clusters (default: true)
- `V4_CFG_SINGLE_ZONE_FALLBACK`: Apply relaxed constraints for single-zone clusters (default: true)

### Usage in ansible-vars.yaml
```yaml
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: true
V4_CFG_MULTI_ZONE_POSTGRES_ENABLED: true
V4_CFG_MULTI_ZONE_CONSUL_ENABLED: true
V4_CFG_MULTI_ZONE_REDIS_ENABLED: true
V4_CFG_MULTI_ZONE_OPENDISTRO_ENABLED: true
V4_CFG_MULTI_ZONE_WORKLOAD_ORCHESTRATOR_ENABLED: true
V4_CFG_MULTI_ZONE_DATA_AGENT_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
V4_CFG_STATEFUL_NODEPOOL_LABEL: "workload.sas.com/class"
V4_CFG_MULTI_ZONE_AUTO_DETECT: true
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

| # | StatefulSet Name | Description | Transformer Target |
|---|------------------|-------------|--------------------|
| 1 | sas-rabbitmq-server | Message queue service | StatefulSet (direct) |
| 2 | sas-crunchy-platform-postgres-* | PostgreSQL database | PostgresCluster CR (Crunchy operator) |
| 3 | sas-consul-server | Service discovery and configuration | StatefulSet (direct) |
| 4 | sas-redis-server | Caching and session store | StatefulSet (direct) |
| 5 | sas-opendistro-default | Search and logging (OpenSearch) | OpenDistroCluster CR (operator-managed) |
| 6 | sas-workload-orchestrator | Job scheduling and orchestration | StatefulSet (direct) |
| 7 | sas-data-agent-server-colocated | Data agent services | StatefulSet (direct) |

### Implementation Notes

**OpenDistro (sas-opendistro-default)**:
- Deployed via Custom Resource: `OpenDistroCluster` (API: `opendistro.sas.com/v1alpha1`)
- Transformer patches the CR at `/spec/template/spec/topologySpreadConstraints`
- The `sas-opendistro-operator` watches the CR and creates the StatefulSet with constraints
- StatefulSet name is `sas-opendistro-default` (not directly patched)

**PostgreSQL (sas-crunchy-platform-postgres)**:
- Managed by Crunchy PostgreSQL Operator
- Transformer patches `PostgresCluster` CR
- Operator creates multiple StatefulSets (e.g., `sas-crunchy-platform-postgres-00-xxxx-0`)
- Uses `ScheduleAnyway` for both zone and hostname constraints (operator default)
- Zone awareness provided without strict enforcement

**Direct StatefulSet Transformers**:
- RabbitMQ, Consul, Redis, Workload Orchestrator, Data Agent
- Transformers directly patch StatefulSet resources
- Use strict zone enforcement (`DoNotSchedule`) with soft hostname spreading (`ScheduleAnyway`)

## Usage

Enable in your ansible-vars.yaml:
```yaml
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: true
V4_CFG_MULTI_ZONE_POSTGRES_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
```

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
