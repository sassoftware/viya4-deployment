# Namespace Monitoring

This sample demonstrates how to customize a monitoring
deployment to separate cluster monitoring from SAS Viya (namespace)
monitoring.

The basic steps are:

* Create the monitoring namespace and label other namespaces for
cluster or SAS Viya monitoring.
* Deploy cluster monitoring and restrict it to use only cluster dashboards.
* Deploy standard SAS Viya monitoring to each SAS Viya namespace.
* Create Prometheus custom resources (CRs) that are configured to monitor only
their respective SAS Viya namespaces.
* Deploy Grafana to each SAS Viya namespace to provide visualization.

All resources in this sample are configured for host-based ingress.

In this example, all three Prometheus instances share the same
instance of AlertManager, to demonstrate how you can centralize alerts. You
can use AlertManager CRs to deploy a separate AlertManager for each instance
of Prometheus.

This sample assumes that you are deploying two SAS Viya namespaces, but you can 
customize the files to deploy to any number of namespaces.

## Installation Instructions

1. Copy this sample directory to a separate local path.

2. Set the `USER_DIR` environment variable to the local path:

```bash
export USER_DIR=/your/path/to/namespace-monitoring
```

3. The sample contains several `.yaml` files that provide values for Grafana, Prometheus and the Prometheus Operator. Edit the copied .yaml files and make these modifications

* Replace the hostnames (`*.host.cluster.example.com`) with values for your deployment
* Replace the namespaces (`viya-one` and `viya-two`) with your namespaces
* Customize any other value in the `.yaml` files as needed for your environment.

4. Change the directory to the base of this repository.

5. Set environment variables to the namespaces:

```bash
# First SAS Viya namespace
export VIYA_ONE_NS=viya-one
# Second SAS Viya namespace
export VIYA_TWO_NS=viya-two
```

6. Create and label the namespaces.

```bash
kubectl create ns monitoring
kubectl label ns kube-system sas.com/cluster-monitoring=true
kubectl label ns ingress-nginx sas.com/cluster-monitoring=true
kubectl label ns monitoring sas.com/cluster-monitoring=true
kubectl label ns cert-manager sas.com/cluster-monitoring=true
kubectl label ns logging sas.com/cluster-monitoring=true

kubectl label ns $VIYA_ONE_NS sas.com/viya-namespace=$VIYA_ONE_NS
kubectl label ns $VIYA_TWO_NS sas.com/viya-namespace=$VIYA_TWO_NS
```

7. Deploy cluster monitoring (including the Prometheus Operator) with a custom user directory and no SAS Viya dashboards.
```bash
VIYA_DASH=false monitoring/bin/deploy_monitoring_cluster.sh
```

8. Deploy standard SAS Viya monitoring components each Viya namespace.
```bash
VIYA_NS=$VIYA_ONE_NS monitoring/bin/deploy_monitoring_viya.sh
VIYA_NS=$VIYA_ONE_NS monitoring/bin/deploy_monitoring_viya.sh
```

9. Deploy Prometheus to each SAS Viya namespace
```bash
kubectl apply -n viya-one -f $USER_DIR/monitoring/prometheus-viya-one.yaml
kubectl apply -n viya-two -f $USER_DIR/monitoring/prometheus-viya-two.yaml
```

10. Deploy Grafana to each SAS Viya namespace
```bash
helm upgrade --install --namespace viya-one grafana-viya-one \
  -f $USER_DIR/monitoring/grafana-common-values.yaml \
  -f $USER_DIR/monitoring/grafana-viya-one-values.yaml stable/grafana
helm upgrade --install --namespace viya-two grafana-viya-two \
  -f $USER_DIR/monitoring/grafana-common-values.yaml \
  -f $USER_DIR/monitoring/grafana-viya-two-values.yaml stable/grafana
```

11. Deploy SAS Viya dashboards to each SAS Viya namespace
```bash
DASH_NS=$VIYA_ONE_NS KUBE_DASH=false LOGGING_DASH=false monitoring/bin/deploy_dashboards.sh
DASH_NS=$VIYA_TWO_NS KUBE_DASH=false LOGGING_DASH=false monitoring/bin/deploy_dashboards.sh
```

## Example Grafana URLs

This sample produces three instances of Grafana - one that displays metrics for the entire cluster, one that displays metrics only from the `viya-one` namespace, and one that displays metrics only from the `viya-two` namespace. These are the sample URLs for the instances of Grafana. The URLs in your deployment depend on the values that you substitute for the namespace names and the host names.  

* [Cluster Grafana - http://grafana.host.cluster.example.com](http://grafana.host.cluster.example.com)
* [Viya-one Grafana - http://grafana.viya-one.host.cluster.example.com](http://grafana.viya-one.host.cluster.example.com)
* [Viya-two Grafana - http://grafana.viya-two.host.cluster.example.com](http://grafana.viya-two.host.cluster.example.com/)

## References

* [Prometheus Operator Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator)
* [Prometheus Operator Custom Resource Definitions](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md)
* [Grafana Helm Chart](https://github.com/helm/charts/tree/master/stable/grafana)
