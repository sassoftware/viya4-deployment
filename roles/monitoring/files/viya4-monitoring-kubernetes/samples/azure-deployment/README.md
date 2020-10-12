# Deployment on Azure

This sample shows the customizations that are necessary if you deploy
on Microsoft Azure. The sample assumes that NGINX ingress is used, but you can modify it for other solutions.

## Instructions

1. Copy this directory to a local directory.
2. Edit the sample yaml files to match your environment.
3. Add additional customization as desired
4. Run the command `export USER_DIR=path/to/my/copy/azure-deployment`.
5. Run the scripts to deploy monitoring and logging components.

## Access the Applications

The monitoring and logging applications re available at these locations (hostnames are replaced with those in the actual environment):

* http://host.cluster.example.com/grafana
* http://host.cluster.example.com/prometheus
* http://host.cluster.example.com/alertmanager
* http://host.cluster.example.com/kibana

This sample uses path-based ingress, but you can use the [ingress sample](../ingress) to modify it to use host-based ingress.
