## Baseline Components and Their Networking Impact

### 1. **Ingress Controllers**

- **ingress-nginx** is deployed as the ingress controller.
- It exposes internal Kubernetes services to external clients, typically via AWS Network Load Balancer (NLB) or cloud-specific load balancers.
- It manages routing of HTTP/HTTPS traffic into the cluster, enforcing TLS, host/path rules, and sometimes source IP restrictions.
- The choice of ingress controller and its configuration (e.g., annotations, load balancer type) directly affects how external traffic enters your cluster.
- **Note:** Ensure that your firewall and security groups allow inbound traffic to the load balancer and that DNS is configured to point to the ingress endpoint.

### 2. **Load Balancers**

- The baseline roles configure and deploy cloud-native load balancers (e.g., AWS NLB) via ingress controllers and service annotations.
- These load balancers provide public or private endpoints for accessing cluster services.
- **Note:** Exposing services via public load balancers may have security implications. Restrict access as needed using security groups, firewall rules, or Kubernetes network policies.

### 3. **Cluster Autoscaler**

- The **cluster-autoscaler** does not directly affect networking, but by scaling nodes up or down, it can impact the availability of network endpoints and the distribution of pods across subnets.
- **Note:** Ensure that your cloud provider IAM roles and API access allow autoscaler operations, and that new nodes can join the cluster network without manual intervention.

### 4. **Metrics Server, Cert-Manager, and Storage CSI Drivers**

- **metrics-server** and **cert-manager** do not directly affect networking, but may require network access to the Kubernetes API and external endpoints (for certificate validation).
- **CSI drivers** (such as NFS, EFS, etc.) do not directly affect networking, but may require network connectivity to storage backends (e.g., EFS, NFS servers).
- **ebs-csi-driver** (AWS only) does not expose services externally, but requires network connectivity to AWS APIs and EBS endpoints for dynamic volume provisioning. This enables persistent storage for pods on AWS and may require outbound access to AWS services.
- **Note:**
    - For NFS/EFS: Ensure that all cluster nodes have network access (NFS/TCP 2049) to the NFS or EFS server. Firewalls and security groups must allow this traffic.
    - For AWS EBS: Nodes must have outbound access to AWS APIs and the correct IAM permissions.
    - For cert-manager: If using ACME (Let's Encrypt), ensure outbound HTTPS access to the internet.

### 5. **Namespace and Resource Management**

- The baseline roles create namespaces and manage resources, which can include network policies or service accounts that affect pod-to-pod communication and access to external resources.
- **Note:** If network policies are enabled, ensure that required inter-pod and pod-to-service communications are allowed. Review any default deny policies.

### 6. **Jump Server (Bastion Host) and SSH Access**

- If a jump server is used, SSH access is required from the Ansible control node to the jump server, and from the jump server to the NFS server (if managing NFS exports or directories).
- **Note:**
    - Ensure that SSH keys are properly configured and distributed.
    - Security groups/firewalls must allow SSH (typically TCP 22) from the control node to the jump server, and from the jump server to the NFS server.
    - The jump server must have the NFS share mounted and accessible at the configured path.

---

## **Summary Table**

|Component|Networking Impact|
|---|---|
|ingress-nginx|Exposes services externally, manages HTTP/S routing, uses cloud load balancers|
|Cluster Autoscaler|Indirectly affects networking by scaling nodes/pods|
|metrics-server|Minimal, requires API access|
|cert-manager|Minimal, may require outbound access for ACME|
|CSI Drivers (NFS, EFS, etc.)|May require network access to storage backends|
|ebs-csi-driver|Requires network connectivity to AWS APIs and EBS endpoints for dynamic volume provisioning; does not expose services externally but enables persistent storage for pods on AWS|
|Jump Server|Requires SSH access from control node and to NFS server; must have NFS share mounted|