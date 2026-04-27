# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with lowercase letter and contain only lowercase alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string
  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
  }
}

variable "location" {
  description = <<EOF
  The GCP Region (i.e. us-east1) or GCP Zone (i.e. us-east1-b) to provision all resources in this script.
  Choosing a Region will make this a multi-zonal cluster.
  If you aren't sure which to choose, go with a ZONE instead of a region.
  If not set, it defaults to the google environment variables, as documented in https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference"
  EOF
  type        = string
}

variable "regional" {
  description = "Should the GKE cluster have a regional or zonal control plane"
  type        = bool
  default     = true
}

variable "service_account_keyfile" {
  description = "Filename of the Service Account JSON file"
  type        = string
  default     = null
}

variable "project" {
  description = "The ID of the GCP Project to use"
  type        = string
}

variable "tf_enterprise_integration_enabled" {
  description = "Modify IAC workflow/resource creation to support integration with Terraform Enterprise"
  type        = bool
  default     = false
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this providers infrastructure."
  type        = string
  default     = "terraform"
}

## Channel - UNSPECIFIED/STABLE/REGULAR/RAPID
variable "kubernetes_channel" {
  description = "The GKE cluster channel for auto-updates"
  type        = string
  default     = "UNSPECIFIED"
}

# Google Cloud will utilize the current default value for the given channel.
# A specific version can be provided to override the default.
# Available Versions: gcloud container get-server-config
#                     https://cloud.google.com/kubernetes-engine/docs/release-notes
variable "kubernetes_version" {
  description = "The GKE cluster K8S version"
  type        = string
  default     = "latest"

  validation {
    condition     = (can(regex("^\\d.\\d+.\\d+-gke.\\d+$", var.kubernetes_version)) || var.kubernetes_version == "latest" || can(regex("^\\d.\\d+$", var.kubernetes_version)) || can(regex("^\\d.\\d+.\\d+$", var.kubernetes_version)))
    error_message = "The format for kubernetes version is: major.minor.patch-gke.N, major.minor, major.minor.patch, or 'latest'."
  }
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map(any)
  default     = {}
}

variable "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], lower(var.cluster_api_mode))
    error_message = "ERROR: Supported values for `cluster_api_mode` are - public, private."
  }
}
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM"
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server"
  type        = list(string)
  default     = null
}

variable "ssh_public_key" {
  description = "File name of public ssh key for jump and nfs VM"
  type        = string
  default     = null
}

# Bastion VM
variable "create_jump_vm" {
  description = "Toggle creation of the Jump VM"
  type        = bool
  default     = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  type        = string
  default     = "jumpuser"
}

variable "jump_vm_type" {
  description = "Jump VM type"
  type        = string
  default     = "n2-standard-4"
}

variable "create_jump_public_ip" {
  description = "Add public ip to jump VM"
  type        = bool
  default     = true
}

variable "jump_rwx_filestore_path" {
  description = "OS path used for NFS integration"
  type        = string
  default     = "/viya-share"
}

# NFS VM
variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM"
  type        = string
  default     = "nfsuser"
}

variable "nfs_vm_type" {
  description = "NFS VM type"
  type        = string
  default     = "n2-highmem-4"
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID5 cluster"
  type        = number
  default     = 1000
}

variable "create_nfs_public_ip" {
  description = "Add public ip to the NFS server VM"
  type        = bool
  default     = false
}

variable "storage_type" {
  description = <<-EOF
    Type of storage to provision for RWX volumes.
    - "standard" : Provisions Google Filestore (ZONAL - single zone only, NOT zone-redundant).
                   Suitable for single-zone GKE deployments only.
    - "ha"        : Provisions Google NetApp Volumes (Zone-Redundant).
                   Required for Multi-Zone GKE deployments.
    NOTE: Google Filestore is ZONAL and does NOT provide zone-redundant storage.
          For Multi-Zone GKE deployments, always use storage_type = "ha" (NetApp Volumes).
    NOTE: storage_type="none" is for internal use only.
  EOF
  type    = string
  default = "standard"
  validation {
    condition     = contains(["standard", "ha", "none"], lower(var.storage_type))
    error_message = "ERROR: Supported values for `storage_type` are - standard, ha."
  }
}

variable "storage_type_backend" {
  description = <<-EOF
    The storage backend used for the chosen storage type.
    - storage_type = "standard" : backend is always "nfs" (Google Filestore - ZONAL).
    - storage_type = "ha"        : backend is always "netapp" (Google NetApp Volumes - Zone-Redundant).
    NOTE: Filestore is no longer a valid backend for storage_type = "ha".
          For Multi-Zone HA deployments, NetApp Volumes is the only supported zone-redundant RWX backend.
  EOF
  type    = string
  default = "nfs"

  validation {
    condition     = contains(["nfs", "filestore", "netapp", "none"], lower(var.storage_type_backend))
    error_message = "ERROR: Supported values for `storage_type_backend` are nfs, filestore, netapp or none."
  }
}

variable "minimum_initial_nodes" {
  description = "Number of initial nodes to aim for to overcome the Ingress quota limit of 100"
  type        = number
  default     = 6
}

# Default Node pool config
variable "default_nodepool_vm_type" {
  description = "Type of the default nodepool VMs"
  type        = string
  default     = "n2-highmem-8"
}

variable "default_nodepool_local_ssd_count" {
  description = "Number of local ssd disks to provision for the default nodepool"
  type        = number
  default     = 0
}

variable "default_nodepool_os_disk_size" {
  description = "Disk size for default nodepool VMs in GB"
  type        = number
  default     = 128
}

variable "default_nodepool_max_nodes" {
  description = "Maximum number of nodes for the default nodepool"
  type        = number
  default     = 5
}

variable "default_nodepool_min_nodes" {
  description = "Minimum number of nodes for the default nodepool"
  type        = number
  default     = 1
}

variable "default_nodepool_taints" {
  description = "Taints for the default nodepool VMs"
  type        = list(any)
  default     = []
}

variable "default_nodepool_labels" {
  description = "Labels to add to the default nodepool VMs"
  type        = map(any)
  default     = {}
}

# Multi-zonal cluster support - Experimental - may change, use at your own risk
variable "default_nodepool_locations" {
  description = "GCP zone(s) where the default nodepool will allocate nodes in. Comma separated list."
  type        = string
  default     = ""
}

variable "node_pools" {
  description = "Node pool definitions"
  type = map(object({
    vm_type           = string
    os_disk_size      = number
    min_nodes         = string
    max_nodes         = string
    node_taints       = list(string)
    node_labels       = map(string)
    local_ssd_count   = number
    accelerator_count = number
    accelerator_type  = string
  }))
  default = {
    cas = {
      "vm_type"      = "n2-highmem-16"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
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
      "min_nodes"    = 1
      "max_nodes"    = 1
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
      "min_nodes"    = 1
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
      "min_nodes"    = 1
      "max_nodes"    = 2
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
    }
  }
}

# Multi-zonal cluster support - Experimental - may change, use at your own risk
# TODO - NOTE
#   This was made external to the node_pools map variable since a requirement of terraform v1.0.0 (the minimum version
#   we require, see versions.tf) is that for variables with nested fields, all attributes are required otherwise
#   execution fails.
#   In Terraform v1.3+ you can mark nested attributes as optional.
#   Since this is an experimental change, at the moment I do no want to impose new requirements on existing users.
#   Potentially we upgrade Terraform modules and versions and we bump our minimum required terraform version to be >1.3
#   then at that time I can deprecate this variable and instead allow the user to configure node_locations per node pool.
#   Refer to https://github.com/hashicorp/terraform/issues/29407#issuecomment-1150491619

variable "nodepools_locations" {
  description = "GCP zone(s) where the additional node pools will allocate nodes in. Comma separated list."
  type        = string
  default     = ""
}

variable "enable_cluster_autoscaling" {
  description = "Setting this value will enable cluster_autoscaling a per-cluster configuration of Node Auto-Provisioning with Cluster Autoscaler to automatically adjust the size of the cluster and create/delete node pools based on the current needs of the cluster's workload."
  type        = bool
  default     = false
}

variable "cluster_autoscaling_max_cpu_cores" {
  description = "Max number of cores in the cluster"
  type        = number
  default     = 500
}

variable "cluster_autoscaling_max_memory_gb" {
  description = "Max number of gb of memory in the cluster"
  type        = number
  default     = 10000
}

variable "cluster_autoscaling_profile" {
  description = "Configuration options for the Autoscaling profile feature, which lets you choose whether the cluster autoscaler should optimize for resource utilization or resource availability when deciding to remove nodes from a cluster"
  type        = string
  default     = "BALANCED"
}

# PostgreSQL

# Defaults
variable "postgres_server_defaults" {
  description = "default values for a postgres server"
  type        = any
  default = {
    machine_type                           = "db-custom-4-16384"
    storage_gb                             = 128
    backups_enabled                        = true
    backups_start_time                     = "21:00"
    backups_location                       = null
    backups_point_in_time_recovery_enabled = false
    backup_count                           = "7" # Number of backups to retain, not days
    administrator_login                    = "pgadmin"
    administrator_password                 = "my$up3rS3cretPassw0rd"
    server_version                         = "15"
    availability_type                      = "ZONAL"
    ssl_enforcement_enabled                = true
    database_flags                         = []
    edition                                = "ENTERPRISE"
  }
}

# User inputs
variable "postgres_servers" {
  description = "Map of PostgreSQL server objects"
  type        = any
  default     = null
 
  # Checking for user provided "default" server
  validation {
    condition     = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? contains(keys(var.postgres_servers), "default") : false : true
    error_message = "ERROR: The provided map of PostgreSQL server objects does not contain the required 'default' key."
  }

  # Checking server name
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : alltrue([
        length(k) > 0,
        length(k) < 88,
        can(regex("^[a-z]+[a-z0-9-]*[a-zA-Z0-9]$", k)),
      ])
    ]) : false : true
    error_message = "ERROR: The database server name must start with a letter, cannot end with a hyphen, must be between 1-88 characters in length, and can only contain hyphens, letters, and numbers."
  }

  # Validate edition and machine type based on PostgreSQL version
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : (
        # If the object is empty, use default values
        length(keys(v)) == 0 ? true : (
          can(try(v.server_version, null)) && 
          can(try(v.edition, null)) && 
          can(try(v.machine_type, null)) && (
            (tonumber(try(v.server_version, "15")) >= 16 && try(v.edition, "ENTERPRISE") == "ENTERPRISE_PLUS" && can(regex("^db-perf-optimized-N-", try(v.machine_type, "")))) ||
            (tonumber(try(v.server_version, "15")) < 16 && try(v.edition, "ENTERPRISE") == "ENTERPRISE" && can(regex("^db-custom-", try(v.machine_type, ""))))
          )
        )
      )
    ]) : false : true
    error_message = "ERROR: Invalid PostgreSQL configuration:\n* PostgreSQL 16+ requires ENTERPRISE_PLUS edition and db-perf-optimized-N-* machine type\n* PostgreSQL < 16 requires ENTERPRISE edition and db-custom-* machine type"
  }
}

## filestore
variable "filestore_size_in_gb" {
  description = "Size in GB of Filesystem in the Google Filestore Instance"
  type        = number
  default     = null
}

variable "filestore_tier" {
  description = "The service tier for the Google Filestore Instance"
  type        = string
  default     = "BASIC_HDD"
  validation {
    # we allow the old values "STANDARD" and "PREMIUM" but do not document them
    condition     = (contains(["STANDARD", "PREMIUM", "BASIC_HDD", "BASIC_SSD"], upper(var.filestore_tier)))
    error_message = "Filestore tier must be one of BASIC_HDD, BASIC_SSD."
  }
}

variable "enable_registry_access" {
  description = "Enable access from GKE to the Project Container Registry."
  type        = bool
  default     = true
}

## Google NetApp Volumes
variable "netapp_service_level" {
  description = "Service level of the storage pool. Possible values are: PREMIUM, EXTREME, STANDARD, FLEX."
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = var.netapp_service_level != null ? contains(["PREMIUM", "EXTREME", "STANDARD", "FLEX"], var.netapp_service_level) : null
    error_message = "ERROR: netapp_service_level - Valid values include - PREMIUM, EXTREME, STANDARD, FLEX."
  }
}

variable "netapp_protocols" {
  description = "The target volume protocol expressed as a list. Each value may be one of: NFSV3, NFSV4, SMB. Currently, only NFS is supported."
  type        = list(string)
  default     = ["NFSV3"]

  validation {
    condition     = var.netapp_protocols != null ? startswith(var.netapp_protocols[0], "NFS") : null
    error_message = "ERROR: Currently, only NFS protocol is supported."
  }
}

variable "netapp_capacity_gib" {
  description = "Capacity of the storage pool (in GiB). Storage Pool capacity specified must be between 2048 GiB and 10485760 GiB."
  type        = string
  default     = 2048
}

variable "netapp_volume_path" {
  description = "A unique file path for the volume. Used when creating mount targets. Needs to be unique per location."
  type        = string
  default     = "export"
}

# GKE Monitoring
variable "create_gke_monitoring_service" {
  description = "Enable GKE metrics from pods in the cluster to the Google Cloud Monitoring API."
  type        = bool
  default     = "false"
}

variable "gke_monitoring_service" {
  description = "Value of the Google Cloud Monitoring API to use if monitoring is enabled. Values are: monitoring.googleapis.com, monitoring.googleapis.com/kubernetes, none"
  type        = string
  default     = "none"
}

variable "gke_monitoring_enabled_components" {
  description = "List of services to monitor: SYSTEM_COMPONENTS, WORKLOADS (WORKLOADS deprecated in 1.24)."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus for your cluster"
  type        = bool
  default     = false
}

# Network
variable "vpc_name" {
  description = "Name of existing VPC. Leave blank to have one created"
  type        = string
  default     = ""
}

variable "nat_address_name" {
  description = "Name of existing ip address for Cloud NAT"
  type        = string
  default     = ""
}

variable "subnet_names" {
  description = "Map subnet usage roles to existing subnet and secondary range names. Required when vpc_name is set."
  type        = map(string)
  default     = {}
  # Example:
  # subnet_names = {
  # gke = "my_gke_subnet"
  # gke_pods_range_name = "my_secondary_range_for_pods"
  # gke_services_range_name = "my_secondary_range_for_services"
  # misc = "my_misc_subnet"}
  # }
}

variable "gke_subnet_cidr" {
  description = "Address space for the subnet for the GKE resources"
  type        = string
  default     = "192.168.0.0/23"
}

variable "misc_subnet_cidr" {
  description = "Address space for the the auxiliary resources (Jump VM and optionally NFS VM) subnet"
  type        = string
  default     = "192.168.2.0/24"
}

variable "gke_pod_subnet_cidr" {
  description = "Secondary address space in the GKE subnet for Kubernetes Pods"
  type        = string
  default     = "10.0.0.0/17"
}

variable "gke_service_subnet_cidr" {
  description = "Secondary address space in the GKE subnet for Kubernetes Services"
  type        = string
  default     = "10.1.0.0/22"
}

variable "gke_control_plane_subnet_cidr" {
  description = "Address space for the hosted primary subnet"
  type        = string
  default     = "10.2.0.0/28"
}

variable "filestore_subnet_cidr" {
  description = "Address space for Google Filestore subnet"
  type        = string
  default     = "192.168.3.0/29"
}

variable "database_subnet_cidr" {
  description = "Address space for Google Cloud SQL Postgres subnet"
  type        = string
  default     = "192.168.4.0/23"
}

variable "netapp_subnet_cidr" {
  description = "Address space for Google Cloud NetApp Volumes subnet"
  type        = string
  default     = "192.168.5.0/24"
}

variable "gke_network_policy" {
  description = "Sets up network policy to be used with GKE CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are true (calico) and false (kubenet). Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = true
}

variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations - Values : default, minimal"
  type        = string
  default     = "default"
}

# Community Contribution
# Disabling this feature will prevent the deployment of a new private IP range and network peeering when utilizing
# HA storage with Netapp Volumes. This should be utilized when a project has pre-existing networking components that 
# include the network peering configuration for Netapp. Otherwise, this feature should remain a True to allow the 
# networking configuration to be deployed.
variable "community_netapp_networking_components_enabled" {
  description = "Community Contribution. Enable/Disable the deployment of Networking components for Netapp resources. Enabled by default."
  type        = bool
  default     = true
}