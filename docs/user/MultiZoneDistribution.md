# Multi-Zone StatefulSet Distribution - Implementation Guide

## Overview
This implementation provides balanced multi-zone pod distribution for StatefulSets in AKS, EKS, and GKE clusters to prevent quorum loss during zone failures while ensuring reliable scheduling.

## Configuration Variables

### Core Settings (roles/vdm/defaults/main.yaml)
- `V4_CFG_MULTI_ZONE_ENABLED`: Master switch for multi-zone distribution (default: true)
- `V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED`: RabbitMQ distribution control (default: true)  
- `V4_CFG_MULTI_ZONE_POSTGRES_ENABLED`: PostgreSQL distribution control (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_RESTRICTION`: Restrict to stateful nodepools (default: true)

### Usage in ansible-vars.yaml
```yaml
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: true
V4_CFG_MULTI_ZONE_POSTGRES_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
```

## Implementation Details

### Topology Spread Constraints (Balanced Approach)
- **Zone Distribution**: `maxSkew: 1` on `topology.kubernetes.io/zone` with `DoNotSchedule`
  - Distributes pods across zones with some tolerance for imbalance
  - Ensures scheduling reliability while maintaining zone distribution
- **Node Distribution**: `maxSkew: 1` on `kubernetes.io/hostname` with `DoNotSchedule`
  - Spreads pods across nodes when possible

### Node Affinity (Nodepool Restriction)
- **Required Node Affinity**: `agentpool=stateful` restriction
  - Ensures StatefulSets only schedule on nodes with `agentpool=stateful` label
  - Prevents cross-nodepool scheduling that could compromise zone isolation

### Preferred Pod Anti-Affinity
- **Host Distribution**: Preferred anti-affinity for `kubernetes.io/hostname`
  - Attempts to spread pods across different nodes when possible
  - Uses weight: 100 preference (not required)

## Key Benefits

- **Zone Failure Protection**: Distributes StatefulSet replicas across zones
- **Nodepool Isolation**: Prevents StatefulSets from mixing with stateless workloads  
- **Quorum Safety**: Single zone failure won't compromise StatefulSet availability
- **Reliable Scheduling**: Balanced constraints allow successful deployment
- **Multi-Cloud Support**: Works with AKS, EKS, and GKE

## Usage

Enable in your ansible-vars.yaml:
```yaml
V4_CFG_MULTI_ZONE_ENABLED: true
V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED: true
V4_CFG_MULTI_ZONE_POSTGRES_ENABLED: true
V4_CFG_STATEFUL_NODEPOOL_RESTRICTION: true
```

## Nodepool Requirements
Ensure your stateful nodepool is labeled:
```bash
kubectl label nodes <stateful-node> workload.sas.com/class=stateful
```