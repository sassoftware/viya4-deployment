# Logging

## Introduction

This document outlines the steps needed to deploy a set of log collection and
monitoring components for SAS Viya 4.x. These components provide a
comprehensive solution for collecting, transforming and surfacing all of the
log messages generated throughout SAS Viya 4.x. These components collect logs
from all pods in a Kubernetes cluster, not only the pods used for SAS Viya.

You must have cluster-admin access to any cluster in which you deploy these
components. You cannot deploy successfully if you have access only to a
namespace or a subset of namespaces.

### Components

These components are deployed:

* [Fluent Bit](https://fluentbit.io/) - Log collection with limited transformation
* [Elasticsearch](https://www.elastic.co/) - Unstructured document storage and query engine
* [Kibana](https://www.elastic.co/kibana) - User interface for query and visualization
* [Prometheus Exporter for Elasticsearch](https://github.com/justwatchcom/elasticsearch_exporter) -
Provides detailed Elasticsearch performance information for Prometheus

## Perform Pre-Deployment Tasks

### Clone the Repository

* From a command line, create a directory to contain the cloned repository.
* Change to the directory you created.
* Clone the repository
* `cd` to the repository directory
* If you have already cloned the repository, use the `git pull` command to
ensure that you have the most recent updates.

### Customize the Deployment

### USER_DIR

Setting the `USER_DIR` environment variable allows for any user customizations
to be stored outside of the directory structure of this repository. The default
`USER_DIR` is the root of this repository. A directory referenced by `USER_DIR`
should include `user*` files in the same relative structure as they exist in
this repository.

The following files are automatically used by the monitoring scripts if available
in `USER_DIR`:

* `user.env`
* `logging/user.env`
* `logging/user-values-elasticsearch-open.yaml`
* `logging/user-values-es-exporter.yaml`
* `logging/user-values-fluent-bit-open.yaml`

#### Use user.env

The `logging/user.env` file contains flags to customize the components that are
deployed as well as to specify some script behavior (such as enabling debug).

#### Modify user-values-*.yaml

The logging stack uses the following Helm charts:

* **Opendistro Elasticsearch**
  * [Chart](https://github.com/opendistro-for-elasticsearch/opendistro-build/tree/master/helm)
  * [Default values](https://github.com/opendistro-for-elasticsearch/opendistro-build/blob/master/helm/opendistro-es/values.yaml)
* **Fluent Bit**
  * [Chart](https://github.com/helm/charts/tree/master/stable/fluent-bit)
  * [Default values](https://github.com/helm/charts/blob/master/stable/fluent-bit/values.yaml)
* **Elasticsearch Exporter**
  * [Chart](https://github.com/helm/charts/tree/master/stable/elasticsearch-exporter)
  * [Default values](https://github.com/helm/charts/blob/master/stable/elasticsearch-exporter/values.yaml)

To change any of the Helm chart values used by either the Elasticsearch
(including Kibana) or Fluent Bit charts, edit the appropriate
`user-values-*.yaml` file listed below:

* For Elasticsearch (and Kibana), modify
`logging/user-values-elasticsearch-open.yaml`.

* For Fluent Bit, modify `logging/user-values-fluent-bit-open.yaml`.
Note that the Fluent Bit configuration files are generated from a
Kuberenetes configMap which is created from the
`fluent-bit_config.configmap_open.yaml` file. Therefore, any edits that you
make in the `user-values-fluent-bit-open.yaml` file that are intended to
affect the Fluent Bit configuration files are ignored. However, edits
affecting other aspects of the Fluent Bit Helm chart execution are processed.

When you edit the `user-values-fluent-bit.yaml` file, ensure that the parent
item of any item that you uncomment is also uncommented.  For
example, if you uncommented the `storageClass` item for the Elasticsearch
master nodes, you must also uncomment the `persistence` item, the
`master` item and the `elasticsearch` item, as shown below:

```yaml
# Sample user-values-elasticsearch-open.yaml

elasticsearch:     # Uncommented b/c 'master' is uncommented
  master:          # Uncommented b/c 'persistenance' is uncommented
    persistence:   # Uncommented b/c 'storageClass' is uncommented
      storageClass: alt-storage  # Uncommented to direct ES to alt-storage storageClass
```

### Evaluate Storage Considerations

#### Provision Persistent Volumes or Persistent Volume Claims

Multiple persistent volume claims (PVCs) are created when Elasticsearch is
installed. The depoyment script assumes that your cluster has some form of
dynamic volume provisioning in place that will automatically provision
storage to support PVCs. However, if your cluster
does not have such a provisioner, you must manually create the
necessary persistent volumes (PVs) before you run the deployment scripts.

#### Using a Different Kubernetes Storage Class

To prevent Elasticsearch and your SAS Viya deployment from competing for
the same disk space, you might want to direct the Elasticsearch PVCs
to a different Kubernetes storageClass. This prevents contention
and insulates each one from storage issues that are caused by the other. For
example, if you use different storageClasses and your SAS Viya deployment
runs out of disk space, Elasticsearch continues to operate.

To specify an alternate storageClass to use, modify the appropriate
`user-values-*.yaml` file used for Helm processing, as described above.
By default, the lines referencing the storageClass in the persistence stanza of the
`user-values-*.yaml` file are commented out, which specifies that
the default storage class is used. To direct the Elasticsearch PVCs to use an
alternate storageClass, edit the file to uncomment the appropriate lines
and confirm the storageClassName matches your preferred storageClass.
The example used in the section ___"Modify user-values-*.yaml"___ above
illustrates this change.

## Deploy SAS Viya Logging

To deploy the logging components, ensure that you are in the directory into
which you cloned the repository and issue this command:

```bash
./logging/bin/deploy_logging_open.sh
```

By default, the components are deployed into the namespace `logging`.

## Update Logging Components

Updates in place are supported if you use Helm 3.x. To update, re-run the
`deploy_logging_open.sh` script to install the latest versions of the
applications, indexes, and dashboards.

If you use Helm 2.x, you must remove and re-install the logging components in
order to update them.

## Remove Logging Components

To remove the monitoring components, run the following commands:

```bash
cd <kube-viya-monitoring repo directory>

logging/bin/remove_logging_open.sh
```

## Validate Your Deployment

### Access Kibana

If the deployment process completes without errors, a message such as this
appears in the console window:

```text
=====================================================================
== Access Kibana using this URL: http://myK8snode:31033/app/kibana ==
=====================================================================
```

The message provides the URL address for the Kibana application. To validate
that the deployment was successful and confirm that all of the logging components
are working, access Kibana and review the log messages that are collected.

__Note:__ The displayed URL for Kibana might not be correct if you defined
ingress objects or if your networking rules alter how hosts are accessed. If
this is the case, contact your Kubernetes administator to determine the proper
host, port and/or path to access Kibana.

### Use Kibana to Validate Logging

* Start Kibana in a browser using the URL provided at the end of the
deployment process. The default credentials for Kibana are `admin`:`admin`.
* If you see a dialog prompting you to __"Try our sample data"__
or __"Explore on my own"__, select __"Explore on my own"__
* Click on the __Tenants__ icon in the toolbar on the left side of Kibana.
  * On the Select Tenant page, click __Select__ in the __Global__ row, which
  makes the Global tenant the active tenant. The text __Active tenant: Global__
  appears above the list of tenants. You only need to perform this action the
  first time you run Kibana.
* Click on the __Dashboard__ icon in the toolbar.
  * If the Dashboard page displays the header __Editing New Dashboard__, select
  the __Dashboard__ icon again. The Dashboards page appears and displays a list
  of dashboards.
  * In the list of dashboards, click on __Log Message Volumes with Level__.
  * The __Log Message Volumes with Level__ dashboard appears, which shows the
  log message volumes over time broken down by the source of the log messages.
  * The __Log Messages__ table (below the charts) displays log messages, with
  the newest messages at the top, based on the current filters. You can filter
  messages by entering text in the query box, selecting  __Add filter__, or
  clicking a log source entry in the legend next to the
  __Message Volumes over Time by Source__ chart.

* Select the __Discover__ icon in the toolbar to display the Discover page. Use
this page to review the collected log messages. You can use the query box or
__Add filter__ to filter the messages that are displayed.
