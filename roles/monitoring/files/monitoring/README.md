# Monitoring

## Introduction

This document outlines the steps needed to deploy a set of monitoring
components that provide the ability to monitor resources in a SAS Viya 4.x
environment. These components support monitoring of SAS Viya 4.x resources
for each SAS Viya namespace as well as monitoring for Kubernetes cluster
resources.

You must have cluster-admin access to any cluster in which you deploy these
components. You cannot deploy successfully if you have access only to a
namespace or a subset of namespaces.

### Components

These components are deployed:

* Prometheus Operator
* Prometheus
* Alert Manager
* Grafana
* node-exporter
* kube-state-metrics
* Prometheus adapter for Kubernetes metrics APIs
* Prometheus Pushgateway
* Grafana dashboards
* Kubernetes cluster alert definitions

## Perform Pre-Deployment Tasks

### Clone the Repository

* From a command line, create a directory to contain the cloned repository.
* Change to the directory you created.
* Clone the repository
* `cd` to the repository directory

If you have already cloned the repository, use the `git pull` command to ensure
that you have the most recent updates.

If you use TLS to encrypt network traffic, you must perform manual steps prior
to deployment. See the **TLS Support** section below for more information.

## Customize the Deployment

### USER_DIR

Setting the `USER_DIR` environment variable allows for any user customizations
to be stored outside of the directory structure of this repository. The default
`USER_DIR` is the root of this repository. A directory referenced by `USER_DIR`
should include `user*` files in the same relative structure as they exist in
this repository.

The following files are automatically used by the monitoring scripts if they
are present in `USER_DIR`:

* `user.env`
* `monitoring/user.env`
* `monitoring/user-values-prom-operator.yaml`
* `monitoring/user-values-pushgateway.yaml`

### user.env

The `monitoring/user.env` file contains environment variable flags that customize
the components that are deployed or to alter some script behavior (such as to
enable debug output). All values in `user.env` files are exported as environment
variables available to the scripts. A `#` as the first character in a line
is treated as a comment.

### user-values-*.yaml

The monitoring stack uses the following Helm charts:

* **Prometheus Operator** - used by `deploy_monitoring_cluster.sh`
  * [Chart](https://github.com/helm/charts/blob/master/stable/prometheus-operator/README.md)
  * [Default values](https://github.com/helm/charts/blob/master/stable/prometheus-operator/values.yaml)
* **Prometheus Pushgateway** - used by `deploy_monitoring_viya.sh`
  * [Chart](https://github.com/helm/charts/tree/master/stable/prometheus-pushgateway)
  * [Default values](https://github.com/helm/charts/blob/master/stable/prometheus-pushgateway/values.yaml)

These charts are highly customizable. Although the default values might be
suitable, you might need to customize some values (such as for ingress,
for example). The Prometheus Operator helm chart, in particular, aggregates
other helm charts such as Grafana and the Prometheus Node Exporter. Links
to the charts and default values are included in the
`user-values-prom-operator.yaml` file.

**Note:** If you are using a cloud provider, you must use ingress, rather than
NodePorts. Use the samples in the
[monitoring/samples/ingress](https://github.com/sassoftware/kube-viya-monitoring/tree/master/monitoring/samples/ingress)
area of this repository to set up either host-based or path-based ingress.

## Istio Integration

This repository contains an optional set of dashboards for Istio. These
dashboards use these assumptions:

* Istio is installed in the `istio-system` namespace
* The optional Prometheus instance that is included with Istio is deployed

To enable Istio support, set `ISTIO_ENABLED=true` in `$USER_DIR/user.env`
or `$USER_DIR/monitoring/user.env` before deploying monitoring using the 
`deploy_monitoring_cluster.sh` script.

### Recommendations

The default configuration of the Prometheus instance that is included in Istio 
monitors the entire Kubernetes cluster. This configuration is typically not preferred if 
you are deploying the monitoring components in this repository.

This is because the Prometheus instance that is included with Istio discovers and scrapes pods that have the
`prometheus.io/*` annotations, including SAS Viya components. If you also deployed the Prometheus 
instance in this repository, both instances of Prometheus are scraping the pods, which leads to higher resource usage. 

To prevent this situation, disable cluster-wide scraping of
pods and services that contain the `prometheus.io/*` annotations by disabling the following
jobs in the Istio Prometheus instance:

* `kubernetes-pods`
* `kubernetes-service-endpoints`

## Deploy Cluster Monitoring Components

To deploy the monitoring components for the cluster, issue this command:

```bash
# Deploy cluster monitoring (can be done before or after deploying Viya)
monitoring/bin/deploy_monitoring_cluster.sh
```

## Deploy SAS Viya Monitoring Components

Scripts may be run from any directory, but a current working directory
of the root of this repository is assumed for the examples below.

To enable direct monitoring of SAS Viya components, run the following command,
which deploys ServiceMonitors and the Prometheus Pushgateway for each SAS Viya
namespace:

```bash
# Deploy exporters and ServiceMonitors for a Viya deployment
# Specify the Viya namespace by setting VIYA_NS
VIYA_NS=<your_viya_namespace> monitoring/bin/deploy_monitoring_viya.sh
```

By default, the components are deployed into the namespace `monitoring`.

## Access Monitoring Applications

NodePorts are used by default. If you deployed using NodePorts, the monitoring
applications are available at these locations by default:

* Grafana - Port 31100 `http://master-node.yourcluster.example.com:31100`
* Prometheus - Port 31090 `http://master-node.yourcluster.example.com:31090`
* AlertManager - Port 31091 `http://master-node.yourcluster.example.com:31091`

The default credentials for Grafana are `admin`:`admin`.

## Update Monitoring Components

Updates in-place are supported. To update, pull and clone the desired version
of this repository, then re-run the
`deploy_monitoring_cluster.sh` and/or `deploy_monitoring_viya.sh`
scripts to pick up the latest versions of the applications, dashboards, service
monitors, and exporters.

## Remove Monitoring Components

To remove the monitoring components, run the following commands:

```bash
# Remove cluster monitoring
monitoring/bin/remove_monitoring_cluster.sh

# Optional: Remove SAS Viya monitoring
# Run this section once per Viya namespace
export VIYA_NS=<your_viya_namespace>
monitoring/bin/remove_monitoring_viya.sh
```

Removing cluster monitoring does not remove persistent volume claims
by default. A re-install after removal should retain existing data.
Manually delete the PVCs or the namespace to delete previously
collected monitoring data.

## TLS Support

You can use the `TLS_ENABLE` or `MON_TLS_ENABLE` settings in user.env
to enable TLS support, which encrypts network traffic
between pods for use by the monitoring pods.

You must perform manual steps prior to deployment in order to enable TLS.
In addition, configuring HTTPS ingress involves a separate set of
steps, which are similar to those needed for SAS Viya.

See the [TLS Sample](samples/tls) for more information.

## Miscellaneous Notes and Troubleshooting

### Expose kube-proxy Metrics

Some clusters are deployed with the kube-proxy metrics listen
address set to `127.0.0.1`, which prevents Prometheus from collecting
metrics. To enable kube-proxy metrics, which are used in the
`Kubernetes / Proxy` dashboard, run this command:

```bash
kubectl edit cm -n kube-system kube-proxy
# Change metricsBindAddress to 0.0.0.0:10249
# Restart all kube-proxy pods
kubectl delete po -n kube-system -l k8s-app=kube-proxy
# Pods will automatically be recreated
```
