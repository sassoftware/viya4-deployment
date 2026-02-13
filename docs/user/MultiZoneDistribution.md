# Strict Multi-Zone Pod Distribution - Implementation Guide

## Overview
This implementation provides strict multi-zone pod distribution for StatefulSets in AKS, EKS, and GKE clusters to prevent quorum loss during zone failures.

## Features Added

### 1. Configuration Variables (roles/vdm/defaults/main.yaml)
- `V4_CFG_MULTI_ZONE_ENABLED`: Master switch for strict multi-zone distribution (default: true)
- `V4_CFG_MULTI_ZONE_RABBITMQ_ENABLED`: RabbitMQ-specific distribution (default: true)  
- `V4_CFG_MULTI_ZONE_POSTGRES_ENABLED`: PostgreSQL-specific distribution (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_RESTRICTION`: Restrict StatefulSets to dedicated nodepools (default: true)
- `V4_CFG_STATEFUL_NODEPOOL_LABEL`: Label for stateful nodepool identification (default: workload.sas.com/class)

### 2. Transformers Created
- `rabbitmq-zone-distribution.yaml`: RabbitMQ strict zone distribution and nodepool restriction
- `postgres-zone-distribution.yaml`: PostgreSQL strict zone distribution and nodepool restriction
- `multi-zone-pod-distribution.yaml`: General StatefulSet strict distribution rules

### 3. Restrictive Implementation Details

#### Strict Topology Spread Constraints
- **Zone Distribution**: `maxSkew: 0` on `topology.kubernetes.io/zone` with `DoNotSchedule`
  - Ensures perfectly even distribution across zones
  - Prevents scheduling if it would create imbalance
- **Node Distribution**: `maxSkew: 1` on `kubernetes.io/hostname` with `DoNotSchedule`
  - Prevents multiple pods on same node

#### Required Pod Anti-Affinity Rules
- **Zone-level**: Required anti-affinity to prevent pods in same zone
- **Node-level**: Preferred anti-affinity to avoid same node (weight: 100)

#### Nodepool Restrictions
- **Required Node Affinity**: Stateful workloads must run on nodes with:
  - `workload.sas.com/class: stateful` label
  - `agentpool` label (ensures managed nodepool)

### 4. Acceptance Criteria Compliance

**More Restrictive Pod Topology Constraints**:
- `maxSkew: 0` for zone distribution (most restrictive)
- `DoNotSchedule` for both zone and node constraints
- Required anti-affinity rules

**Restrict StatefulSets to One Nodepool**:
- Node affinity requires `workload.sas.com/class=stateful`
- Ensures StatefulSets run only on designated stateful nodepool

### 5. Benefits
- **Zero Quorum Loss Risk**: Strict zone distribution prevents cluster failures
- **Dedicated Resources**: Stateful workloads isolated to specific nodepool
- **Predictable Scheduling**: Clear constraints for placement decisions
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