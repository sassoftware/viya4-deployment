# Azure Monitor Integration

## Scrape Prometheus Metrics Endpoints

SAS Viya components are natively instrumented to expose a Prometheus-compatible
HTTP(S) metrics endpoint. Azure Monitor can be configured to automatically
discover and scrape these endpoints.

See the [Azure documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-prometheus-integration)
to get started. After enabling Azure Montitor for your cluster, download the
[template](https://github.com/microsoft/Docker-Provider/blob/ci_dev/kubernetes/container-azm-ms-agentconfig.yaml)
ConfigMap yaml. Customize the `prometheus-data-collection-settings` section.
Recommended changes include:

* `interval` - Update from `1m` to `30s` (recommended, but not required)
* `monitor_kubernetes_pods` - Set to `true`.

A minimal sample yaml file is available [here](container-azm-ms-agentconfig.yaml).

This enables auto-discovery of
pods to monitor based on the standard Prometheus annotations. SAS Viya
components that expose metrics endpoints should include these annotations:

* `promethues.io/scrape` - `true` or `false`
* `promethues.io/path` - path to metrics endpoint
* `promethues.io/port`- metrics port
* `promethues.io/scheme`- `http` or `https`

After customizing the template, it simply needs to be applied to the cluster:

```bash
kubectl apply -f /path/to/container-azm-ms-agentconfig.yaml
```

It may take 3-5 minutes for the monitoring agents to restart and for data
collection to begin.

## Example Queries

The following are some sample queries to demonstrate how to visualize the newly
collected Prometheus metric data.

### go_threads for sas-types

```text
InsightsMetrics
| where Namespace == "prometheus"
| where Name == "go_threads"
| where parse_json(Tags).app == "sas-types"
```

### Resident memory for a service in MB

```text
InsightsMetrics
| extend T=parse_json(Tags)
| where Namespace == "prometheus"
| where Name == "process_resident_memory_bytes"
| where T.app == "sas-types"
| project TimeGenerated, Name, ResidentMemoryMB=Val/1024/1024
```text

### Show a metric across multiple services

```text
InsightsMetrics
| where Namespace == "prometheus"
| where Name == "go_threads"
| project TimeGenerated, tostring(App = parse_json(Tags).app), Val
| render timechart
```

### Show sas_* metrics for a service

```text
InsightsMetrics
| where Namespace == "prometheus"
| where Name matches regex "sas_"
| where parse_json(Tags).app == "sas-types"
| extend App = tostring(App = parse_json(Tags).app)
| project TimeGenerated, Name, App, Val
| render timechart
```

### Calculate Rate

```text
InsightsMetrics
| extend App = tostring(App = parse_json(Tags).app)
| where Namespace == "prometheus"
| where Name == "go_memstats_alloc_bytes_total"
| where App == "sas-types"
| summarize Val=any(Val) by TimeGenerated=bin(TimeGenerated, 1m), Name, App
| sort by TimeGenerated asc
| project TimeGenerated, Name, App, Val - prev(Val)
| render timechart
```

## Links

* [Azure Prometheus Integration](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-prometheus-integration)
* [Querying Azure Metrics](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-log-search#search-logs-to-analyze-data)
