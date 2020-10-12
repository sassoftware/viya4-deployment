# Samples

Samples are provided to demonstrate how to customize the deployment
of the logging and monitoring components for specific situations. The samples provide instructions and example yaml files that you can modify to fit your environment. Although each example focuses on a specific scenario, you can combine multiple samples by merging the appropriate values in each deployment file.

These samples are provided:

* [azure-deployment](azure-deployment) - Deploys on Microsoft Azure Kubernetes Service (AKS)
* [azure-monitor](azure-monitor) - Enables Azure Monitor to collect metrics
from SAS Viya components
* [external-alertmanager](external-alertmanager) - Configures a central external Alert Manager instance
* [generic-base](generic-base) - Does not support a specific scenario, but provides a full set of customization files with comments
* [ingress](ingress) - Deploys using host-based or path-based ingress
* [min-logging](min-logging) - Provides a minimal logging configuration for dev or test environments
* [namespace-monitoring](namespace-monitoring) - Separates cluster monitoring
from SAS Viya monitoring
* [tls](tls) - Enables TLS encryption for both ingress and in-cluster
communication
