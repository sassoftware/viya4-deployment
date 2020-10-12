# Ingress

This sample demonstrates how to deploy monitoring and logging components
configured with ingress instead of node ports. You can choose to use host-based routing or path-based routing. Use host-based routing if the monitoring applications (Prometheus, AlertManager, and Grafana) will be on different hosts. Use path-based routing if the applications use different paths on the same host.

If you are using a cloud provider, you must deploy using ingress.

## Preparation for Deployment

1. Copy this sample directory to a separate local path.

2. Set the `USER_DIR` environment variable to the local path:

```bash
export USER_DIR=/path/to/my/copy/ingress
```

3. To enable TLS, edit `$USER_DIR/user.env` and set `TLS_ENABLED` to `true`

### Monitoring 

Follow these steps to deploy monitoring using ingress:

1. The monitoring deployment process requires that the user response file be
named `$USER_DIR/monitoring/user-values-prom-operator.yaml`.

If you are using host-based routing, rename the
`user-values-prom-host.yaml` to `user-values-prom-operator.yaml`. 

If you are using path-based routing, rename the `user-values-prom-path.yaml` to `user-values-prom-operator.yaml`.

2. Edit `$USER_DIR/monitoring/user-values-prom-operator.yaml` and replace
all instances of `host.cluster.example.com` with hostnames that match your cluster.

3. Deploy monitoring using the standard deployment script:

```bash
/path/to/this/repo/monitoring/bin/deploy_monitoring_cluster.sh
```

### Logging

Follow these steps to deploy logging using ingress:

1. The logging deployment process requires that the user response file be
named `$USER_DIR/logging/user-values-elasticsearch-open.yaml`.

If you are using host-based routing, rename the
`user-values-elasticsearch-host.yaml` to `user-values-elasticsearch-open.yaml`. 

If you are using path-based routing, rename the `user-values-elasticsearch-path.yaml` to `user-values-elasticsearch-open.yaml`.

2. Edit `$USER_DIR/logging/user-values-elasticsearch-open.yaml` and replace
all instances of `host.cluster.example.com` with hostnames that match your cluster

3. Deploy logging using the standard deployment script:

```bash
/path/to/this/repo/logging/bin/deploy_logging_open.sh
```

## Access the Applications

If you deploy using host-based ingress, the applications are available at these
locations (with hostnames replaced with those in the actual environment that you specified):

* Grafana - `https://grafana.host.mycluster.example.com`
* Prometheus - `https://prometheus.host.mycluster.example.com`
* AlertManager - `https://alertmanager.host.mycluster.example.com`
* Kibana - `https://kibana.host.mycluster.example.com`

If you deploy using path-based ingress, the applications are available at these
locations (with hostnames replaced with those in the actual environment that you specified):

* Grafana - `http://host.mycluster.example.com/grafana`
* Prometheus - `http://host.mycluster.example.com/prometheus`
* AlertManager - `http://host.mycluster.example.com/alertManager`
* Kibana - `http://host.mycluster.example.com/kibana`

The default credentials for Grafana and Kibana are `admin`:`admin`.
