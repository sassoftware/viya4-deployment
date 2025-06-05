### Third-party components
The following is a list of the third-party components currently in full support/used by the Viya4 DaC. You can also find the chart repo URLs referenced in the repo [README](../README.md).

| Component         | Chart Name        | Chart Source URL                                                                                         | Container Registry              | Purpose                                                                                                 | Cloud Provider Support           |
|------------------|-------------------|----------------------------------------------------------------------------------------------------------|-------------------------------|---------------------------------------------------------------------------------------------------------|----------------------------------|
| ingress-nginx    | ingress-nginx     | https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx                              | quay.io                       | Provides ingress controller for Kubernetes.                                                             | AWS, Azure, GCP, generic K8s     |
| cert-manager     | cert-manager      | https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager                     | quay.io                       | Manages TLS certificates in Kubernetes.                                                                 | AWS, Azure, GCP, generic K8s     |
| metrics-server   | metrics-server    | https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server                     | registry.k8s.io               | Collects resource metrics from K8s nodes and pods.                                                      | AWS only                         |
| csi-driver-nfs   | csi-driver-nfs    | https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/charts                                     | registry.k8s.io, gcr.io       | Provides NFS storage provisioning for Kubernetes (supports AWS EFS, GCP Filestore, Azure Files, NFS).   | AWS, Azure, GCP, generic NFS     |
| ebs-csi-driver   | aws-ebs-csi-driver| https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/charts/aws-ebs-csi-driver             | public.ecr.aws                | Provides dynamic provisioning of AWS EBS volumes for persistent storage in Kubernetes.                  | AWS only                         |

**Notes:**
- These are the only third-party components installed by default by the DaC.
- All components are installed and managed via Ansible playbooks and Helm charts.
- Chart versions are managed in the Ansible variables and can be overridden by the user if needed.
- All components are compatible with AWS, Azure, and GCP unless otherwise noted. `metrics-server` and `ebs-csi-driver` are for AWS only.
- For more details on how to add or update these components, see the main playbook in `playbooks/playbook.yaml` and the role documentation in the `roles/` directory.