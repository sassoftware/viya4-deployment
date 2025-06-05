## Baseline Components and Networking Considerations

### 1. **Ingress Controllers**

- **ingress-nginx** is deployed as the ingress controller.
- It exposes internal Kubernetes services to external clients, typically via AWS Network Load Balancer (NLB) or cloud-specific load balancers.
- It manages routing of HTTP/HTTPS traffic into the cluster, enforcing TLS, host/path rules, and sometimes source IP restrictions.
- The choice of ingress controller and its configuration (e.g., annotations, load balancer type) directly affects how external traffic enters your cluster.
- **Note:**
    - Ensure that your firewall and security groups allow inbound traffic to the load balancer and that DNS is configured to point to the ingress endpoint.
    - **Common endpoints that may need to be allowed:**
        - Ingress controller endpoints (HTTP/HTTPS)
        - Cloud load balancer endpoints (varies by provider)
    - **Container registries that may need to be allowlisted:**
        - quay.io
        
### 2. **Load Balancers**

- The baseline roles configure and deploy cloud-native load balancers (e.g., AWS NLB) via ingress controllers and service annotations.
- These load balancers provide public or private endpoints for accessing cluster services.
- Annotations are used to make/specify that the load balancer is either public or private.
- **Note:**
    - Exposing services via public load balancers may have security implications. Restrict access as needed using security groups, firewall rules, or Kubernetes network policies.
    - **Common endpoints that may need to be allowed:**
        - Load balancer endpoints (public/private IPs, HTTP/HTTPS)
        - Health check endpoints (varies by provider)

### 3. **Cluster Autoscaler**

- The **cluster-autoscaler** by scaling nodes up or down, it can impact the availability of network endpoints and the distribution of pods across subnets.
- **Note:**
    - Ensure that your cloud provider IAM roles and API access allow autoscaler operations, and that new nodes can join the cluster network without manual intervention.
    - **Common endpoints that may need to be allowed:**
        - Cloud provider APIs (for scaling, usually outbound HTTPS)
        - Kubernetes API server (internal cluster traffic)

### 4. **Metrics Server, Cert-Manager, and Storage CSI Drivers**

- **metrics-server** and **cert-manager** may require network access to the Kubernetes API and external endpoints (for certificate validation).
- **CSI drivers** (such as NFS, EFS, etc.) may require network connectivity to storage backends (e.g., EFS, NFS servers).
- **ebs-csi-driver** (AWS only) does not expose services externally, but requires network connectivity to AWS APIs and EBS endpoints for dynamic volume provisioning. This enables persistent storage for pods on AWS and may require outbound access to AWS services.
- **Note:**
    - For NFS/EFS: Ensure that all cluster nodes have network access (NFS/TCP 2049) to the NFS or EFS server. Firewalls and security groups must allow this traffic.
    - For AWS EBS: Nodes must have outbound access to AWS APIs and the correct IAM permissions.
    - For cert-manager: If using ACME (Let's Encrypt), ensure outbound HTTPS access to the internet.
    - **Common endpoints that may need to be allowed:**
        - Kubernetes API server (internal cluster traffic)
        - NFS/EFS storage (TCP 2049)
        - AWS APIs (for EBS, outbound HTTPS)
        - Certificate authorities (e.g., Let's Encrypt ACME, outbound HTTPS)
    - **Container registries that may need to be allowlisted:**
        - metrics-server: registry.k8s.io
        - cert-manager: quay.io
        - csi-driver-nfs: registry.k8s.io, gcr.io
        - ebs-csi-driver: public.ecr.aws

### 5. **Namespace and Resource Management**

- The baseline roles create namespaces and manage resources, which can include network policies or service accounts that affect pod-to-pod communication and access to external resources.
- **Note:**
    - If network policies are enabled, ensure that required inter-pod and pod-to-service communications are allowed. Review any default deny policies.
    - **Common endpoints that may need to be allowed:**
        - Pod-to-pod and pod-to-service communication (internal cluster traffic)
        - External services as required by workloads

### 6. **Jump Server (Bastion Host) and SSH Access**

- If a jump server is used, SSH access is required from the Ansible control node to the jump server, and from the jump server to the NFS server (if managing NFS exports or directories).
- **Note:**
    - Ensure that SSH keys are properly configured and distributed.
    - Security groups/firewalls must allow SSH (typically TCP 22) from the control node to the jump server, and from the jump server to the NFS server.
    - The jump server must have the NFS share mounted and accessible at the configured path.
    - **Common endpoints that may need to be allowed:**
        - SSH (TCP 22) from control node to jump server
        - SSH (TCP 22) from jump server to NFS server
        - NFS (TCP 2049) from jump server to NFS server

### 7. **Viya Deployment Manager (VDM)**

- The Viya Deployment Manager (VDM) role orchestrates the deployment of core SAS Viya services and supporting infrastructure. It may create internal or external services (such as Postgres or Elasticsearch), configure ingress and TLS, expose endpoints (e.g., SAS/CONNECT, Consul UI), and manage storage overlays. VDM can also affect namespace isolation and network policies, especially in multi-tenant environments. Review VDM configuration and deployment options to ensure all required network access is permitted.
- **Note:**
    - VDM may expose new endpoints or require connectivity to internal/external databases, storage, or certificate authorities. Ensure that firewalls, security groups, and network policies allow required traffic for all VDM-managed services and integrations, especially in multi-tenant or restricted environments.
    - **Common endpoints that may need to be allowed:**
        - Ingress controller endpoints (HTTP/HTTPS)
        - SAS/CONNECT load balancer endpoints
        - Consul UI (port 8500, if enabled)
        - Internal/external Postgres (default port 5432)
        - Internal Elasticsearch (default port 9200)
        - NFS/EFS storage (TCP 2049)
        - AWS APIs (for EBS, outbound HTTPS)
        - Certificate authorities (e.g., Let's Encrypt ACME, outbound HTTPS)
        - Container registries (for pulling images, outbound HTTPS)
    - **Container registries that may need to be allowlisted:**
        - quay.io
        - registry.k8s.io
        - gcr.io
        - mcr.microsoft.com
        - public.ecr.aws
        - (plus any additional registries for SAS Viya images and other required workloads)

---

### Container Registries to Allowlist by Cloud Provider

#### AWS
- quay.io (ingress-nginx, cert-manager)
- registry.k8s.io (metrics-server, csi-driver-nfs)
- gcr.io (csi-driver-nfs)
- public.ecr.aws (ebs-csi-driver)

#### Azure
- quay.io (ingress-nginx, cert-manager)
- registry.k8s.io (csi-driver-nfs)
- gcr.io (csi-driver-nfs)

#### GCP
- quay.io (ingress-nginx, cert-manager)
- registry.k8s.io (csi-driver-nfs)
- gcr.io (csi-driver-nfs)

#### Generic K8s / NFS
- quay.io (ingress-nginx, cert-manager)
- registry.k8s.io (csi-driver-nfs)
- gcr.io (csi-driver-nfs)

**Notes:**
- `metrics-server` and `ebs-csi-driver` are AWS only, so their registries are not needed for Azure or GCP.
- If you are using only a specific cloud provider, you only need to allowlist the registries listed for that provider.

---

## **Summary Table**

|Component|Networking Considerations|
|---|---|
|ingress-nginx|Exposes services externally, manages HTTP/S routing, uses cloud load balancers|
|Cluster Autoscaler|Indirectly affects networking by scaling nodes/pods|
|metrics-server|Minimal, requires API access|
|cert-manager|Minimal, may require outbound access for ACME|
|CSI Drivers (NFS, EFS, etc.)|May require network access to storage backends|
|ebs-csi-driver|Requires network connectivity to AWS APIs and EBS endpoints for dynamic volume provisioning; does not expose services externally but enables persistent storage for pods on AWS|
|Jump Server|Requires SSH access from control node and to NFS server; must have NFS share mounted|
|VDM (Viya Deployment Manager)|May create internal/external services (e.g., Postgres, Elasticsearch), configure ingress/TLS, expose endpoints (e.g., SAS/CONNECT, Consul UI), and require network access to storage backends and certificate authorities. Multi-tenancy may affect namespace isolation and network policies.|