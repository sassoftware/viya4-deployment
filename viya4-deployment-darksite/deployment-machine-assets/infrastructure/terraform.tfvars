# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "darksite-lab"
location                                = "<aws-location-value>" # e.g., "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# Bring your own existing resources - get values from AWS console or VPC/Subnet provisioning script outputs
vpc_id  = "PrivateVPCId" 
subnet_ids = {  # only needed if using pre-existing subnets
  "public" : ["PrivateSubnetAId", "PrivateSubnetBId"],
  "private" : ["PrivateSubnetAId", "PrivateSubnetBId"],
  "control_plane" : ["ControlPlaneSubnetAId", "ControlPlaneSubnetBId"],
  "database" : ["PrivateSubnetAId", "PrivateSubnetBId"] # only when 'create_postgres=true'
}

security_group_id = "PrivateVpcSGId"
cluster_security_group_id = "PrivateClusterControlSGId"
workers_security_group_id = "PrivateClusterWorkersSGId"

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = []  # e.g., ["123.45.6.89/32"]  # not required in a darksite
ssh_public_key              = "/workspace/ssh/id_rsa.pub"     # container path to ssh public key used for jumpserver
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
# postgres_servers = {
#   default = {},
# }

## Cluster config
cluster_api_mode                        = "private"
kubernetes_version                      = "1.26"
default_nodepool_node_count             = 1
default_nodepool_vm_type                = "m5.2xlarge"

## General
storage_type                            = "standard" 
nfs_raid_disk_type                      = "gp3"
nfs_raid_disk_iops                      = "3000"

## Cluster Node Pools config
node_pools = {
  cas = {
    "vm_type" = "m5.2xlarge"
    "cpu_type" = "AL2_x86_64"
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  compute = {
    "vm_type" = "m5.8xlarge"
    "cpu_type" = "AL2_x86_64"
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  services = {
    "vm_type" = "m5.4xlarge"
    "cpu_type" = "AL2_x86_64"
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes" = 0
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  }
}

# Jump Server
create_jump_vm                        = true
create_jump_public_ip                 = false
