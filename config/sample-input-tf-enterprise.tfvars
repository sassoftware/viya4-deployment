# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
#
# NOTE: For Terraform Cloud/Enterprise these variables should be defined
#       in the workspace in terraform cloud/enterprise as a terraform variable
#
#       You also need to define: GOOGLE_CREDENTIALS as an environment
#       variable.
# prefix         = "<prefix-value>"
# location       = "<gcp-zone-or-region>" # e.g., "us-east1-b"
# project        = "<gcp-project-id>"
# ssh_public_key = "<ssh-public-key>"
# ****************  REQUIRED VARIABLES  ****************

#
# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.
#
# If you need to add your own public ip, use `curl -s ifconfig.me` 
# and append "/32", e.g. 1.2.3.4/32 to create a valid CIDR for use.
#
# !NOTE! - When using Terraform Cloud you must set your access_cidrs to ["0.0.0.0/0"]
#          in order to work. They do not publish their 'helper' agent IPs or assign those
#          per account so no way to predict those values when setting up access CIDRs.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [
  "0.0.0.0/0",
]
create_static_kubeconfig = true
# **************  RECOMMENDED  VARIABLES  ***************

# add labels to the created resources
# tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# GKE config
kubernetes_version         = "1.34"
default_nodepool_min_nodes = 1
default_nodepool_vm_type   = "n2-highmem-8"

## Cluster Node Pools config - minimal
cluster_node_pool_mode = "minimal"
node_pools = {
  cas = {
    "vm_type"      = "n2-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 0
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count"   = 2
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  generic = {
    "vm_type"      = "n2-highmem-4"
    "os_disk_size" = 200
    "min_nodes"    = 0
    "max_nodes"    = 5
    "node_taints"  = []
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
  }
}

# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"
jump_vm_type          = "e2-medium"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_type          = "n2-highmem-4"
nfs_raid_disk_size   = 1000

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# User variables
tf_enterprise_integration_enabled = true
