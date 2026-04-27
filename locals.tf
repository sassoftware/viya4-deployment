# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {

  # General

  # get the region from "location", or else from the local config
  region = var.location != "" ? regex("^[a-z0-9]*-[a-z0-9]*", var.location) : data.google_client_config.current.region

  # get the zone from "location", or else from the local config. If none is set, default to the first zone in the region
  is_region  = var.location != "" ? var.location == regex("^[a-z0-9]*-[a-z0-9]*", var.location) : false
  first_zone = length(data.google_compute_zones.available.names) > 0 ? data.google_compute_zones.available.names[0] : ""
  # all_zones  = length(data.google_compute_zones.available.names) > 0 ? join(",", [for item in data.google_compute_zones.available.names : format("%s", item)]) : ""
  zone = (var.location != "" ? (local.is_region ? local.first_zone : var.location) : (data.google_client_config.current.zone == "" ? local.first_zone : data.google_client_config.current.zone))

  # CIDRs/Network
  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  ssh_public_key = (var.create_jump_vm || var.storage_type == "standard"
    ? can(file(var.ssh_public_key)) ? file(var.ssh_public_key) : var.ssh_public_key != null ? length(var.ssh_public_key) > 0 ? var.ssh_public_key : null : null
    : null
  )

  # Storage
  # Updated: storage_type = "ha" always maps to "netapp" (zone-redundant, required for Multi-Zone).
  # storage_type = "standard" maps to "filestore" (zonal, single-zone only).
  # NOTE: Filestore is ZONAL and does NOT provide zone-redundant storage.
  #       For Multi-Zone HA deployments, always use storage_type = "ha" (NetApp Volumes).
  storage_type_backend = (var.storage_type == "none" ? "none"
    : var.storage_type == "standard" ? "nfs"
  : var.storage_type == "ha" ? "netapp" : "none")

  # Kubernetes
  kubeconfig_path = var.iac_tooling == "docker" ? "/workspace/${var.prefix}-gke-kubeconfig.conf" : "${var.prefix}-gke-kubeconfig.conf"

  # rough calculation to get to 6 initial nodes - in order to overcome the Ingress quota limit of 100
  initial_node_count = ceil((var.minimum_initial_nodes - tonumber(var.default_nodepool_min_nodes)) / length(var.node_pools))

  taint_effects = {
    NoSchedule       = "NO_SCHEDULE"
    PreferNoSchedule = "PREFER_NO_SCHEDULE"
    NoExecute        = "NO_EXECUTE"
  }

  node_pools_and_accelerator_taints = {
    for node_pool, settings in var.node_pools : node_pool => {
      accelerator_count  = settings.accelerator_count
      accelerator_type   = settings.accelerator_type
      local_ssd_count    = settings.local_ssd_count
      max_nodes          = settings.max_nodes
      min_nodes          = settings.min_nodes
      node_labels        = settings.node_labels
      os_disk_size       = settings.os_disk_size
      vm_type            = settings.vm_type
      node_taints        = settings.accelerator_count > 0 ? concat(settings.node_taints, ["nvidia.com/gpu=present:NoSchedule"]) : settings.node_taints
      initial_node_count = max(local.initial_node_count, settings.min_nodes)
      node_locations     = var.nodepools_locations != "" && var.nodepools_locations != null ? var.nodepools_locations : local.zone
    }
  }

  node_pools = merge(local.node_pools_and_accelerator_taints, {
    default = {
      "vm_type"            = var.default_nodepool_vm_type
      "os_disk_size"       = var.default_nodepool_os_disk_size
      "min_nodes"          = var.default_nodepool_min_nodes
      "max_nodes"          = var.default_nodepool_max_nodes
      "node_taints"        = var.default_nodepool_taints
      "node_labels"        = merge(var.tags, var.default_nodepool_labels, { "kubernetes.azure.com/mode" = "system" })
      "local_ssd_count"    = var.default_nodepool_local_ssd_count
      "accelerator_count"  = 0
      "accelerator_type"   = ""
      "initial_node_count" = var.default_nodepool_min_nodes
      "node_locations"     = var.default_nodepool_locations != "" && var.default_nodepool_locations != null ? var.default_nodepool_locations : local.zone
    }
  })

  subnet_names_defaults = {
    gke                     = "${var.prefix}-gke-subnet"
    misc                    = "${var.prefix}-misc-subnet"
    gke_pods_range_name     = "${var.prefix}-gke-pods"
    gke_services_range_name = "${var.prefix}-gke-services"
  }

  subnet_names = length(var.subnet_names) == 0 ? local.subnet_names_defaults : var.subnet_names

  gke_subnet_cidr  = length(var.subnet_names) == 0 ? var.gke_subnet_cidr : module.vpc.subnets["gke"].ip_cidr_range
  misc_subnet_cidr = length(var.subnet_names) == 0 ? var.misc_subnet_cidr : module.vpc.subnets["misc"].ip_cidr_range

  gke_pod_range_index = length(var.subnet_names) == 0 ? index(module.vpc.subnets["gke"].secondary_ip_range[*].range_name, local.subnet_names["gke_pods_range_name"]) : 0
  gke_pod_subnet_cidr = length(var.subnet_names) == 0 ? var.gke_pod_subnet_cidr : module.vpc.subnets["gke"].secondary_ip_range[local.gke_pod_range_index].ip_cidr_range

  filestore_size_in_gb = (
    var.filestore_size_in_gb == null
    ? (contains(["BASIC_HDD", "STANDARD"], upper(var.filestore_tier)) ? 1024 : 2560)
    : var.filestore_size_in_gb
  )

  # PostgreSQL
  postgres_servers    = var.postgres_servers == null ? {} : { for k, v in var.postgres_servers : k => merge(var.postgres_server_defaults, v, ) }
  base_database_flags = [{ name = "max_prepared_transactions", value = "1024" }, { name = "max_connections", value = "1024" }]

  postgres_outputs = length(module.postgresql) != 0 ? { for k, v in module.postgresql :
    k => {
      server_name : module.postgresql[k].instance_name,
      fqdn : module.postgresql[k].private_ip_address,
      admin : local.postgres_servers[k].administrator_login,
      password : local.postgres_servers[k].administrator_password,
      server_port : "5432", # TODO - Create a var when supported
      ssl_enforcement_enabled : local.postgres_servers[k].ssl_enforcement_enabled,
      connection_name : module.postgresql[k].instance_connection_name,
      server_public_ip : length(local.postgres_public_access_cidrs) > 0 ? module.postgresql[k].public_ip_address : null,
      server_cert : module.postgresql[k].instance_server_ca_cert[0].cert,
      service_account : module.sql_proxy_sa[0].service_account.email,
      internal : false,
    }
  } : {}

}
