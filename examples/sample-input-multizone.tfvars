# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                  = "<prefix-value>"
location                = "<gcp-zone-or-region>" # e.g., "us-east1-b"
project                 = "<gcp-project-id>"
service_account_keyfile = "<service-account-json-file>"
#
# ****************  REQUIRED VARIABLES  ****************

# ****************  RECOMMENDED VARIABLES  ****************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# ****************  RECOMMENDED VARIABLES  ****************

# add labels to the created resources
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# GKE config
kubernetes_version         = "1.34"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "n2-highmem-8"

# Node Pools config
node_pools = {
  cas = {
    "vm_type"      = "n2-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count"   = 2
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  compute = {
    "vm_type"      = "n2-highmem-4"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count"   = 1
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  stateless = {
    "vm_type"      = "n2-highmem-4"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 4
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  stateful = {
    "vm_type"      = "n2-highmem-4"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 4
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
  }
}
# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks (ZONAL - single zone only)
#    "ha"       - Google NetApp Volumes (Zone-Redundant - required for Multi-Zone deployments)
#
# IMPORTANT: For Multi-Zone GKE deployments, storage_type = "ha" is required.
#            Google Filestore is a ZONAL service and does NOT provide zone-redundant storage.
#            Google NetApp Volumes is the only supported zone-redundant RWX storage backend
#            for Multi-Zone GKE deployments.
storage_type = "ha"
# storage_type_backend is no longer required. storage_type = "ha" always provisions Google NetApp Volumes.

# GKE cluster control plane configuration
regional = true # e.g., true for regional (multi-zone) control plane, false for zonal

# Default node pool zone locations (comma-separated string)
default_nodepool_locations = "" # e.g., "us-east1-b,us-east1-c,us-east1-d"

# Additional node pool zone locations (comma-separated string)
nodepools_locations = "" # e.g., "us-east1-b,us-east1-c,us-east1-d"

