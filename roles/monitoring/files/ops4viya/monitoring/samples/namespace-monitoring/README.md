# Namespace Monitoring

This is a sample demonstrating a customized monitoring
deployment to separate cluster monitoring from SAS Viya (namespace)
monitoring.

The basic steps are:

* Create the monitoring namespace and label other namespaces for
cluster or SAS Viya monitoring
* Deploy cluster monitoring and restrict it to use only cluster dashboards
* Deploy standard SAS Viya monitoring to each SAS Viya namespace
* Create Prometheus custom resources (CRs) that are configured to monitor only their respective SAS Viya namespaces
* Deploy Grafana to each SAS Viya namespace to provide visualization

All resources in this sample are configured for host-based ingress.

In this example, all three Prometheus instances share the same
instance of AlertManager, mainly to demonstrate how to centralize alerts. You can use AlertManager CRs to deploy a separate AlertManager for each instance of Prometheus.

This sample assumes that you are deploying two SAS Viya namespaces, but it should be
fairly straightforward to customize the files to deploy to any
number of namespaces.

## Deployment

```bash
# cd to the base of this repository

# Set USER_DIR to a working directory outside of this repo
# (change path as desired)
export USER_DIR=~/my-workspace/newdir
# First SAS Viya namespace
export VIYA_ONE_NS=viya-one
# Second SAS Viya namespace
export VIYA_TWO_NS=viya-two
# Copy the sample
cp -R monitoring/samples/namespace-monitoring/* $USER_DIR/

# Edit the copied files:
#   - Replace the hostnames (`*.host.cluster.example.com`)
#   - Replace the namespaces (`viya-one` and `viya-two`)
#   - Further customize user.env/*.yaml files as needed

# Create and label namespaces
kubectl create ns monitoring
kubectl label ns kube-system sas.com/cluster-monitoring=true
kubectl label ns ingress-nginx sas.com/cluster-monitoring=true
kubectl label ns monitoring sas.com/cluster-monitoring=true
kubectl label ns cert-manager sas.com/cluster-monitoring=true
kubectl label ns logging sas.com/cluster-monitoring=true

kubectl label ns $VIYA_ONE_NS sas.com/viya-namespace=$VIYA_ONE_NS
kubectl label ns $VIYA_TWO_NS sas.com/viya-namespace=$VIYA_TWO_NS

# Deploy cluster monitoring (including the Prometheus Operator)
# with a custom user dir and no SAS Viya dashboards

VIYA_DASH=false monitoring/bin/deploy_monitoring_cluster.sh

# Deploy standard SAS Viya monitoring components each Viya namespace
VIYA_NS=$VIYA_ONE_NS monitoring/bin/deploy_monitoring_viya.sh
VIYA_NS=$VIYA_ONE_NS monitoring/bin/deploy_monitoring_viya.sh

# Deploy Prometheus to each SAS Viya namespace
kubectl apply -n viya-one -f $USER_DIR/monitoring/prometheus-viya-one.yaml
kubectl apply -n viya-two -f $USER_DIR/monitoring/prometheus-viya-two.yaml

# Deploy Grafana to each SAS Viya namespace
helm upgrade --install --namespace viya-one grafana-viya-one \
  -f $USER_DIR/monitoring/grafana-common-values.yaml \
  -f $USER_DIR/monitoring/grafana-viya-one-values.yaml stable/grafana
helm upgrade --install --namespace viya-two grafana-viya-two \
  -f $USER_DIR/monitoring/grafana-common-values.yaml \
  -f $USER_DIR/monitoring/grafana-viya-two-values.yaml stable/grafana

# Deploy SAS Viya dashboards to each SAS Viya namespace
DASH_NS=$VIYA_ONE_NS KUBE_DASH=false LOGGING_DASH=false monitoring/bin/deploy_dashboards.sh
DASH_NS=$VIYA_TWO_NS KUBE_DASH=false LOGGING_DASH=false monitoring/bin/deploy_dashboards.sh
```

## URLs

* [Cluster Grafana](http://grafana.host.cluster.example.com)
* [Armstrong Grafana](http://grafana.viya-one.host.cluster.example.com)
* [Aldrin Grafana](http://grafana.viya-two.host.cluster.example.com/)

## References

* [Prometheus Operator Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator)
* [Prometheus Operator Custom Resource Definitions](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md)
* [Grafana Helm Chart](https://github.com/helm/charts/tree/master/stable/grafana)
