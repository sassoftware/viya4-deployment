# Deployment on Azure

This sample contains values appropriate for deployment on Microsoft Azure. The 
sample assumes that NGINX ingress is used, but it can be modified for other solutions.

## Instructions

```bash
export USER_DIR=path/to/my/user-dir
mkdir -p $USER_DIR/monitoring
cp monitoring/samples/azure/deployment/user-values-prom-operator.yaml $USER_DIR/monitoring/
# Edit `$USER_DIR/monitoring/user-values-prom-operator.yaml` and replace the
# example hostname with the real ingress hostname
monitoring/bin/deploy_monitoring_cluster.sh
# Deployment takes a while. After it completes, run
VIYA_NS=my-viya-namespace-here monitoring/bin/deploy_monitoring_viya.sh
```

The monitoring applications are available as root paths under the ingress host:

* http://host.cluster.example.com/grafana
* http://host.cluster.example.com/prometheus
* http://host.cluster.example.com/alertmanager
