# Sample - Ingress Enablement for Monitoring

## Overview

These samples demonstrate how to deploy monitoring components with ingress enabled. You can choose to use host-based routing or path-based routing. Use host-based routing if the monitoring applications (Prometheus, AlertManager, and Grafana) will be on different hosts. Use path-based routing if the applications are in different paths on the same host.

If you are using a clound provider, you must deploy using ingress.

## Instructions

1. Set up an empty directory with a `monitoring` subdirectory to contain the customization files. 

2. Export a `USER_DIR` environment variable that points to this
location. For example:

```bash
mkdir -p ~/my-cluster-files/ops/user-dir/monitoring
export USER_DIR=~/my-cluster-files/ops/user-dir
```

3. If you are using TLS, create `$USER_DIR/monitoring/user.env`. Specify this value in the file:

* `MON_TLS_ENABLE=true` - This flag modifies the deployment of Prometheus,
Grafana, and AlertManager to be TLS-enabled. 

4. Copy the appropriate sample ingress user response files to your `USER_DIR`:

```bash
cp path/to/this/repo/monitoring/samples/ingress/user-values-prom-host.yaml $USER_DIR/monitoring/
```
or
```bash
cp path/to/this/repo/monitoring/samples/ingress/user-values-prom-path.yaml $USER_DIR/monitoring/
```

5. Edit `$USER_DIR/monitoring/user-values-prom-host.yaml` or `$USER_DIR/monitoring/user-values-prom-path.yaml` and replace
all sample hostnames with hostnames for your deployment. Specifically, you must replace
`host.cluster.example.com` with the name of the ingress node. Often, the ingress node is the cluster master node, but your environment might be different.

6. Specify any other customizations in `user-values-prom-host.yaml` or `user-values-prom-path.yaml`.

7. After you have followed these steps to set up `USER_DIR`, deploy cluster
monitoring normally:

```bash
path/to/this/repo/monitoring/bin/deploy_monitoring_cluster.sh
```

## Access Monitoring Applications

If you deploy using host-based ingress, the applications are available at these locations, as specified in `user-values-prom-host.yaml`:

* Grafana - `https://grafana.host.mycluster.example.com`
* Prometheus - `https://prometheus.host.mycluster.example.com`
* AlertManager - `https://alertmanager.host.mycluster.example.com`

If you deploy using path-based ingress, the applications are available at these locations as specified in `user-values-prom-path.yaml`:

* Grafana - `http://host.mycluster.example.com/grafana`
* Prometheus - `hhttp://host.mycluster.example.com/prometheus`
* AlertManager - `hhttp://host.mycluster.example.com/alertManager

The default credentials for Grafana are `admin`:`admin`.
