# Cluster vs. Namespace Monitoring Samples

## Overview

This directory contains sample files demonstrating how to deploy
monitoring so that cluster monitoring is separated from SAS Viya
monitoring. The metric sources, rules, and dashboards are
customized to the set of resources being monitored.

## Customizing Response Files

Ingress and namespace monitoring involve customizing the default deployment
of SAS Viya monitoring. Sample files are provided here for two examples:

## Samples

- **[ingress](ingress)**
  - [Host-based](ingress/user-values-prom-host.yaml)
  Demonstrates how to to define host-based ingress of cluster monitoring
  - [Path-based](ingress/user-values-prom-path.yaml) Demonstrates
  how to to define path-based ingress of cluster monitoring which involves
  a small amount of additional configuration for Grafana
- **[namespace-monitoring](namespace-monitoring)** - This directory contains
a set of response files and documentation on the commands necessary to deploy
host-based ingress of monitoring components that are segregated into cluster
monitoring and SAS Viya namespace monitoring.
