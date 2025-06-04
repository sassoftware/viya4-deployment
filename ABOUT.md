
### Third party components:
1. **ingress-nginx**
    - **Chart:** [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
    - **Chart Name:** `ingress-nginx`
	- **Chart URL:** `https://kubernetes.github.io/ingress-nginx/`
    - **Purpose:** Provides ingress controller for Kubernetes.
2. **cert-manager**
    - **Chart:** [cert-manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
    - **Chart Name:** `cert-manager`
	- **Chart URL:** `https://charts.jetstack.io/`
    - **Purpose:** Manages TLS certificates in Kubernetes.
3. **metrics-server**
    - **Chart:** [metrics-server](https://kubernetes-sigs.github.io/metrics-server/)
    - **Chart Name:** `metrics-server`
	- **Chart URL:** `https://kubernetes-sigs.github.io/metrics-server/`
    - **Purpose:** Collects resource metrics from K8s nodes and pods.
4. **nfs.csi.k8s.io (NFS CSI Provisioner)**
    - **Chart:** [nfs-subdir-external-provisioner](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/)
    - **Chart Name:** (commonly `nfs-subdir-external-provisioner`)
	- **Chart URL:** `https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/`
	- **Note:** The exact chart name may vary; check `nfs-csi-provisioner.yaml` for specifics.
    - **Purpose:** Provides NFS storage provisioning for Kubernetes.
5. **Contour**
    - **Chart:** [contour](https://projectcontour.io/)
    - **Chart Name:** `contour`
	- **Chart URL:** `https://projectcontour.io/`
    - **Purpose:** Alternative ingress controller (if selected).
6. **istio**
    - **Chart:** [istio](https://github.com/istio/istio/releases)
    - **Chart Name:** `istio`
	- **Chart URL:** [https://istio.io/](https://github.com/istio/istio/releases) (Istio provides its own installer script and charts)
    - **Purpose:** Service mesh for traffic management, security, and observability.


### Main playbook overview:
1. **Create Global Temporary Directory**
    
    - Task: `Global tmp dir`
    - Action: Creates a temporary directory for use during the playbook run.
    - Tags: `install`, `uninstall`, `update`, `onboard`, `cas-onboard`, `offboard`
2. **Run Task Validations from Common Role**
    
    - Task: `Common role - task validations`
    - Action: Includes `common` role’s `task-validations` tasks.
    - Tags: `always` (runs every time)
3. **Include Main Tasks from Common Role**
    
    - Task: `Common role`
    - Action: Includes the main tasks from the `common` role, making its variables public.
    - Tags: `install`, `uninstall`, `update`, `onboard`, `cas-onboard`, `offboard`
4. **Optionally Include Jump-Server Role**
    
    - Task: `jump-server role`
    - Action: Includes the `jump-server` role.
    - Condition: Runs only if all of these are defined: `JUMP_SVR_HOST`, `JUMP_SVR_USER`, `JUMP_SVR_PRIVATE_KEY`, `V4_CFG_MANAGE_STORAGE` and if `V4_CFG_MANAGE_STORAGE` is `true`.
    - Tags: `viya`
5. **Optionally Include Baseline Role for Install**
    
    - Task: `baseline role install`
    - Action: Includes the `baseline` role for install actions.
    - Condition: Runs only if both `'baseline'` and `'install'` are in `ansible_run_tags`.
    - Tags: `baseline`
6. **Optionally Include Multi-Tenancy Role**
    
    - Task: `Multi-tenancy role`
    - Action: Includes the `multi-tenancy` role.
    - Condition: Runs only if `V4MT_ENABLE` is defined.
    - Tags: `multi-tenancy`
7. **Include VDM Role**
    
    - Task: `vdm role`
    - Action: Includes the `vdm` role.
    - Tags: `viya`, `multi-tenancy`
8. **Optionally Include Baseline Role for Uninstall**
    
    - Task: `baseline role uninstall`
    - Action: Includes the `baseline` role for uninstall actions.
    - Condition: Runs only if both `'baseline'` and `'uninstall'` are in `ansible_run_tags`.
    - Tags: `baseline`
9. **Delete Temporary Directory**
    
    - Task: `Delete tmpdir`
    - Action: Removes the temporary directory created at the start.
    - Tags: `install`, `uninstall`, `update`
**Summary:**
- Tasks are executed in the order listed above.
- Some tasks/roles are conditionally included based on variables or tags.
- The playbook is designed to be flexible for different deployment scenarios by using tags and conditions.


## Baseline Components and Their Networking Impact

### 1. **Ingress Controllers**

- **ingress-nginx** and **Contour** are deployed as ingress controllers.
- They expose internal Kubernetes services to external clients, typically via AWS Network Load Balancer (NLB) or cloud-specific load balancers.
- They manage routing of HTTP/HTTPS traffic into the cluster, enforcing TLS, host/path rules, and sometimes source IP restrictions.
- The choice of ingress controller and its configuration (e.g., annotations, load balancer type) directly affects how external traffic enters your cluster.

### 2. **Service Mesh (Istio)**

- **Istio** is optionally deployed, providing a service mesh for advanced traffic management, security, and observability.
- Istio injects sidecar proxies into pods, intercepting and controlling all service-to-service traffic.
- It enables features like mutual TLS, traffic splitting, ingress/egress control, and fine-grained authorization policies.
- Istio’s ingress gateway can replace or supplement other ingress controllers, further controlling how traffic enters and leaves the cluster.
### 3. **Load Balancers**

- The baseline roles configure and deploy cloud-native load balancers (e.g., AWS NLB) via ingress controllers and service annotations.
- These load balancers provide public or private endpoints for accessing cluster services.

### 4. **Cluster Autoscaler**

- The **cluster-autoscaler** does not directly affect networking, but by scaling nodes up or down, it can impact the availability of network endpoints and the distribution of pods across subnets.

### 5. **Metrics Server, Cert-Manager, and Storage CSI Drivers**

- **metrics-server** and **cert-manager** do not directly affect networking, but may require network access to the Kubernetes API and external endpoints (for certificate validation).
- **CSI drivers** (EBS, NFS, etc.) do not directly affect networking, but may require network connectivity to storage backends (e.g., EFS, NFS servers).
### 6. **Namespace and Resource Management**

- The baseline roles create namespaces and manage resources, which can include network policies or service accounts that affect pod-to-pod communication and access to external resources.

---

## **Summary Table**

|Component|Networking Impact|
|---|---|
|ingress-nginx|Exposes services externally, manages HTTP/S routing, uses cloud load balancers|
|Contour|Alternative ingress controller, similar impact as ingress-nginx|
|Istio|Controls all service-to-service and ingress/egress traffic, adds security layers|
|Cluster Autoscaler|Indirectly affects networking by scaling nodes/pods|
|metrics-server|Minimal, requires API access|
|cert-manager|Minimal, may require outbound access for ACME|
|CSI Drivers|May require network access to storage backends|
