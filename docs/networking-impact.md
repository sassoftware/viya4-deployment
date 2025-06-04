## Baseline Components and Their Networking Impact

### 1. **Ingress Controllers**

- **ingress-nginx** is deployed as the ingress controller.
- It exposes internal Kubernetes services to external clients, typically via AWS Network Load Balancer (NLB) or cloud-specific load balancers.
- It manages routing of HTTP/HTTPS traffic into the cluster, enforcing TLS, host/path rules, and sometimes source IP restrictions.
- The choice of ingress controller and its configuration (e.g., annotations, load balancer type) directly affects how external traffic enters your cluster.

### 2. **Load Balancers**

- The baseline roles configure and deploy cloud-native load balancers (e.g., AWS NLB) via ingress controllers and service annotations.
- These load balancers provide public or private endpoints for accessing cluster services.

### 3. **Cluster Autoscaler**

- The **cluster-autoscaler** does not directly affect networking, but by scaling nodes up or down, it can impact the availability of network endpoints and the distribution of pods across subnets.

### 4. **Metrics Server, Cert-Manager, and Storage CSI Drivers**

- **metrics-server** and **cert-manager** do not directly affect networking, but may require network access to the Kubernetes API and external endpoints (for certificate validation).
- **CSI drivers** (such as NFS, EFS, etc.) do not directly affect networking, but may require network connectivity to storage backends (e.g., EFS, NFS servers).
- **ebs-csi-driver** (AWS only) does not expose services externally, but requires network connectivity to AWS APIs and EBS endpoints for dynamic volume provisioning. This enables persistent storage for pods on AWS and may require outbound access to AWS services.

### 5. **Namespace and Resource Management**

- The baseline roles create namespaces and manage resources, which can include network policies or service accounts that affect pod-to-pod communication and access to external resources.

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