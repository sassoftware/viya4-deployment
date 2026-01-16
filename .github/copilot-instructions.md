# AI Coding Agent Instructions for viya4-deployment

## Project Overview

This is an **Ansible-based deployment automation** project for SAS Viya 4 platform on Kubernetes. It orchestrates cluster baseline setup, Kustomize-based manifest generation, and SAS Viya deployment across AWS/Azure/GCP environments.

**Critical Limitation**: This project only supports **patch updates** with the exact same manifest. Version upgrades, cadence changes, or new software offerings are not supported (see KB0041450).

## Architecture & Components

### Three-Layer Execution Model
1. **Baseline Role** (`roles/baseline/`) - Deploys cluster-level infrastructure (ingress-nginx, cert-manager, NFS CSI driver, metrics-server, EBS CSI driver for AWS)
2. **VDM Role** (`roles/vdm/`) - Viya Deployment Manager: handles asset retrieval, kustomization.yaml generation, and orchestration tooling
3. **Multi-Tenancy Role** (`roles/multi-tenancy/`) - Optional: onboarding/offboarding tenants with CAS server customizations

### Deployment Orchestration
- Uses **SAS Viya Platform Deployment Operator** (default, `V4_DEPLOYMENT_OPERATOR_ENABLED=true`) or **sas-orchestration CLI** (2022.12+)
- Requires Docker available to run sas-orchestration commands when not using the operator
- Operator can be cluster-scoped (default) or namespace-scoped

### Storage Architecture
```
<NFS_EXPORT>
  /pvs                    # Persistent volumes
  /<NAMESPACE>
    /bin                  # Open source binaries
    /data                 # SAS and CAS data
    /homes                # User home directories  
    /astores              # Model stores
```

## Critical Workflows

### Running Deployments

**Via Docker (Recommended)**:
```bash
docker build -t viya4-deployment .
docker run --group-add root --user $(id -u):$(id -g) \
  --volume $HOME/.kube:/config/kubeconfig \
  --volume $(pwd)/ansible-vars.yaml:/config/config \
  --volume /local/path:/data \
  viya4-deployment --tags "baseline,viya,install"
```

**Via Ansible CLI**:
```bash
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yaml -f
ansible-playbook playbooks/playbook.yaml -e CONFIG=/path/to/ansible-vars.yaml \
  --tags "baseline,viya,install"
```

### Tag System (Critical)
Tags control which roles execute. Combine multiple tags:
- `baseline,install` - Deploy cluster infrastructure
- `viya,install` - Deploy SAS Viya platform
- `baseline,viya,install` - Full stack deployment
- `baseline,uninstall` - Remove cluster infrastructure
- `multi-tenancy` - Tenant operations
- `update` - Apply updates to existing deployment

Set `DEPLOY: false` in ansible-vars.yaml to generate manifests without deploying.

### Terraform State Integration
When using SAS Viya 4 IaC projects (viya4-iac-aws/azure/gcp), set `TFSTATE` variable to auto-discover:
- KUBECONFIG, PROVIDER, CLUSTER_NAME
- RWX filestore endpoints
- Jump server connection details
- PostgreSQL server configs
- Cloud NAT IPs for `LOADBALANCER_SOURCE_RANGES`

See [examples/ansible-vars-iac.yaml](examples/ansible-vars-iac.yaml) for required variables.

## Configuration Conventions

### Variable Naming Pattern
- `V4_CFG_*` - Core configuration (ingress, TLS, storage, PostgreSQL, etc.)
- `V4MT_*` - Multi-tenancy specific variables
- `V4_DEPLOYMENT_OPERATOR_*` - Operator-related settings
- `JUMP_SVR_*` - Jump server connection details
- Provider-specific storage vars use provider prefix (e.g., `V4_CFG_RABBITMQ_STORAGECLASS`)

### Ansible Configuration Specifics
- Uses `hash_behaviour=merge` for deep variable merging
- Custom lookup plugin `tfstate.py` in `roles/common/lookup_plugins/` for IaC integration
- Roles path: `./roles`, library path: `/usr/share/ansible:./plugins/modules`
- SSH configured with `ControlMaster=auto` and `ConnectionAttempts=100`

### Key File Locations
- Main playbook: [playbooks/playbook.yaml](playbooks/playbook.yaml)
- Configuration docs: [docs/CONFIG-VARS.md](docs/CONFIG-VARS.md) (456 lines of variable documentation)
- Example configs: [examples/ansible-vars.yaml](examples/ansible-vars.yaml), [examples/ansible-vars-iac.yaml](examples/ansible-vars-iac.yaml)
- Kustomize overlays: `<BASE_DIR>/<CLUSTER_NAME>/<NAMESPACE>/site-config/`

## Code Patterns

### Role Task Organization
Roles use `main.yaml` to orchestrate includes:
```yaml
# roles/vdm/tasks/main.yaml pattern
- include_tasks: assets.yaml          # Asset retrieval
- include_tasks: kustomize.yaml       # Manifest generation
- include_tasks: deploy.yaml          # Orchestration
  when: DEPLOY|bool and 'install' in ansible_run_tags
```

### Conditional Execution Pattern
```yaml
when:
  - variable is defined
  - variable|bool  # Explicit boolean conversion
  - "'tag_name' in ansible_run_tags"
```

### Docker Volume Mapping Convention
Ansible vars map to Docker mounts: `-e VARIABLE_NAME` → `--volume <path>:/config/variable_name` (lowercase)
Exception: `BASE_DIR` maps to `/data`, vault password file to `/config/vault_password_file`

### Version-Specific Overlay Detection
Critical pattern for handling SAS version changes (see `workload_orchestrator.yaml`):
```yaml
# Check for new overlay structure
- stat: path: "{{ DEPLOY_DIR }}/sas-bases/overlays/component/cluster-role"
  register: component_cluster_role

# Conditionally set resource path based on what exists
- set_fact:
    component_resource: "{{ 
      'overlays/component/cluster-role' if component_cluster_role.stat.exists
      else 'overlays/component' }}"

# Apply only if exists
- overlay_facts:
    add: [{ resources: "overlays/component-server/cluster-role" }]
  when: component_server_cluster_role.stat.exists
```
This handles breaking changes between SAS cadences where overlay structures reorganize.

## IPv6 Dual-Stack Networking

### Supported Providers
- **AWS**: Full IPv6 support with dualstack NLB (enabled via `V4_CFG_ENABLE_IPV6=true`)
- **Azure**: IPv6 dual-stack support added in v9.3.0 (enabled via `V4_CFG_ENABLE_IPV6=true`)
- **GCP**: Not supported

### Configuration Details

**AWS Implementation** (`roles/baseline/defaults/main.yml:98-106`):
```yaml
INGRESS_NGINX_IPV6_CONFIG:
  controller:
    service:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
        service.beta.kubernetes.io/aws-load-balancer-ip-address-type: "dualstack"
        service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      ipFamilies: ["IPv6"]
```

**Azure Implementation** (`roles/baseline/defaults/main.yml:108-113`):
```yaml
INGRESS_NGINX_AZURE_IPV6_CONFIG:
  controller:
    service:
      ipFamilies: ["IPv6", "IPv4"]
      ipFamilyPolicy: "PreferDualStack"
```

### Prerequisites
- **AWS EKS**: Enable `ipv6_enabled=true` in viya4-iac-aws, requires IPv6 CIDR block on VPC
- **Azure AKS**: Enable IPv6 dual-stack at cluster creation time with Azure CNI networking, Standard SKU load balancer required
- **LOADBALANCER_SOURCE_RANGES**: Supports both IPv4 (e.g., "10.0.0.0/8") and IPv6 (e.g., "2001:db8::/32") CIDR notation

### Task Execution
Conditional logic in `roles/baseline/tasks/ingress-nginx.yaml:82-100`:
- AWS: Applies when `PROVIDER == "aws"` and `V4_CFG_ENABLE_IPV6 == true`
- Azure: Applies when `PROVIDER == "azure"` and `V4_CFG_ENABLE_IPV6 == true`
- Merges IPv6 config into `INGRESS_NGINX_CONFIG` using Ansible's `combine()` filter

## Testing & Debugging

### Common Issues
- **Storage classes**: AWS uses `io2-vol-mq`/`io2-vol-pg`, Azure uses `managed-csi-premium-v2-mq`/`managed-csi-premium-v2-pg`
- **External PostgreSQL**: Requires cloud authentication setup for GCP (see [docs/user/AnsibleCloudAuthentication.md](docs/user/AnsibleCloudAuthentication.md))
- **Mirror repository**: Not supported with Deployment Operator + LTS 2021.1
- **Workload Orchestrator (2025.12+)**: Multi-tier architecture changes require DaC to detect and add both:
  - `overlays/sas-workload-orchestrator/cluster-role` (or legacy `overlays/sas-workload-orchestrator`)
  - `overlays/sas-workload-orchestrator-server/cluster-role` (if exists)
  
  Fixed in v9.2.0+ via PR #693. Code checks for cluster-role subdirectories using `stat.exists` and `stat.isdir` to ensure directories (not files) are detected. Enable debug output by setting `when: true` in the debug task to troubleshoot overlay detection.

### Validation
- Task validations run with `tags: always` in common role
- Set `DEPLOY: false` to dry-run and validate generated manifests in `<BASE_DIR>/<CLUSTER_NAME>/<NAMESPACE>/`
- Workload orchestrator controlled by `V4_WORKLOAD_ORCHESTRATOR_ENABLED` (default: true, cadence 2023.08+)

## Dependencies

- **Container Runtime**: Python 3, Ansible collections (ansible.utils 5.1.2, community.docker 3.13.0, kubernetes.core 5.0.0)
- **CLI Tools**: kubectl 1.33.7, helm 3.17.1, AWS CLI 2.24.16, Azure CLI, GCP SDK 513.0.0
- **Cloud CLIs**: Embedded in Docker image for provider authentication
- **Skopeo**: Built from source (release-1.16) for image operations

## Multi-Tenancy Specifics

Tenants require namespace-level isolation with customizations in `roles/multi-tenancy/tasks/`:
- `multi-tenant-setup.yaml` - Initial MT configuration
- `multi-tenant-onboard-offboard.yaml` - Tenant lifecycle
- `tenant-cas-customizations.yaml` - CAS server pod templates per tenant
- `onboard-offboard-cas-servers.yaml` - CAS server provisioning

Enable with `V4MT_ENABLE` variable and use `--tags multi-tenancy` for operations.
