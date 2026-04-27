# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## GCP-GKE
#
# Terraform Registry : https://registry.terraform.io/namespaces/terraform-google-modules
# GitHub Repository  : https://github.com/terraform-google-modules
#
# Terraform Cloud : Credentials are supplied with GOOGLE_CREDENTIALS a single line JSON
#                   file containing the output of gcloud login. When copy the contents
#                   of that output you must remove all newlines and store this as a single
#                   line entry as a variable
#
provider "google" {
  credentials = var.service_account_keyfile != null ? can(file(var.service_account_keyfile)) ? file(var.service_account_keyfile) : null : null
  project     = var.project
  default_labels = {
    goog-partner-solution = "isol_plb32_0014m00001h35jvqaa_qxe2gvexrm4ooh7tfz7tvel7ffjdujvk"
  }
}

provider "google-beta" {
  credentials = var.service_account_keyfile != null ? can(file(var.service_account_keyfile)) ? file(var.service_account_keyfile) : null : null
  project     = var.project
}
provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
}

data "google_client_config" "current" {}

# Used for locals below.
data "google_compute_zones" "available" {
  region = local.region
}

data "external" "git_hash" {
  count   = var.tf_enterprise_integration_enabled ? 0 : 1
  program = ["files/tools/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  count   = var.tf_enterprise_integration_enabled ? 0 : 1
  program = ["files/tools/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  count = var.tf_enterprise_integration_enabled ? 0 : 1
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = data.external.git_hash[0].result["git-hash"]
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
version: ${data.external.iac_tooling_version[0].result["terraform_version"]}
revision: ${data.external.iac_tooling_version[0].result["terraform_revision"]}
provider-selections: ${data.external.iac_tooling_version[0].result["provider_selections"]}
outdated: ${data.external.iac_tooling_version[0].result["terraform_outdated"]}
EOT
  }

  depends_on = [module.gke]
}

resource "google_filestore_instance" "rwx" {
  name  = "${var.prefix}-rwx-filestore"
  # Filestore is a ZONAL service and does NOT provide zone-redundant storage.
  # Filestore is only provisioned for storage_type = "standard" (single-zone deployments).
  # For Multi-Zone / HA deployments, use storage_type = "ha" which provisions NetApp Volumes.
  count    = var.storage_type == "standard" && local.storage_type_backend == "filestore" ? 1 : 0
  tier     = upper(var.filestore_tier)
  location = local.zone
  labels   = var.tags

  file_shares {
    capacity_gb = local.filestore_size_in_gb
    name        = "volumes"
  }

  networks {
    network           = module.vpc.network_name
    modes             = ["MODE_IPV4"]
    reserved_ip_range = var.filestore_subnet_cidr
  }
}

data "google_container_engine_versions" "gke-version" {
  provider       = google-beta
  location       = var.regional ? local.region : local.zone
  version_prefix = "${var.kubernetes_version}."
}

module "gke" {
  source                        = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                       = "~> 36.2.0"
  project_id                    = var.project
  name                          = "${var.prefix}-gke"
  region                        = local.region
  regional                      = var.regional
  zones                         = [local.zone]
  network                       = module.vpc.network_name
  subnetwork                    = local.subnet_names["gke"]
  ip_range_pods                 = local.subnet_names["gke_pods_range_name"]
  ip_range_services             = local.subnet_names["gke_services_range_name"]
  http_load_balancing           = false
  horizontal_pod_autoscaling    = true
  deploy_using_private_endpoint = var.cluster_api_mode == "private" ? true : false
  enable_private_endpoint       = var.cluster_api_mode == "private" ? true : false
  enable_private_nodes          = true
  master_ipv4_cidr_block        = var.gke_control_plane_subnet_cidr

  node_pools_metadata     = { "all" : var.tags }
  cluster_resource_labels = var.tags

  add_cluster_firewall_rules = true

  release_channel    = var.kubernetes_channel
  kubernetes_version = var.kubernetes_channel == "UNSPECIFIED" ? var.kubernetes_version : data.google_container_engine_versions.gke-version.release_channel_default_version[var.kubernetes_channel]

  network_policy           = var.gke_network_policy
  remove_default_node_pool = true

  grant_registry_access = var.enable_registry_access

  monitoring_service            = var.create_gke_monitoring_service ? var.gke_monitoring_service : "none"
  monitoring_enabled_components = var.create_gke_monitoring_service ? var.gke_monitoring_enabled_components : []

  monitoring_enable_managed_prometheus = var.enable_managed_prometheus

  # allows the cluster to be deleted by TF
  deletion_protection = false

  cluster_autoscaling = var.enable_cluster_autoscaling ? {
    enabled : true,
    max_cpu_cores : var.cluster_autoscaling_max_cpu_cores,
    max_memory_gb : var.cluster_autoscaling_max_memory_gb,
    min_cpu_cores : 1,
    min_memory_gb : 1,
    gpu_resources       = [],
    auto_repair         = (var.kubernetes_channel == "UNSPECIFIED") ? false : true,
    auto_upgrade        = (var.kubernetes_channel == "UNSPECIFIED") ? false : true
    autoscaling_profile = var.cluster_autoscaling_profile
    } : {
    enabled : false,
    max_cpu_cores : 0,
    max_memory_gb : 0,
    min_cpu_cores : 0,
    min_memory_gb : 0,
    gpu_resources       = [],
    auto_repair         = (var.kubernetes_channel == "UNSPECIFIED") ? false : true,
    auto_upgrade        = (var.kubernetes_channel == "UNSPECIFIED") ? false : true
    autoscaling_profile = var.cluster_autoscaling_profile
  }

  master_authorized_networks = concat([
    for cidr in(local.cluster_endpoint_public_access_cidrs) : {
      display_name = cidr
      cidr_block   = cidr
      }], [{
      display_name = "VPC"
      cidr_block   = module.vpc.subnets["gke"].ip_cidr_range
      }], [{
      display_name = "MISC"
      cidr_block   = module.vpc.subnets["misc"].ip_cidr_range
  }])

  node_pools = [
    for nodepool, settings in local.node_pools : {
      name               = nodepool
      machine_type       = settings.vm_type
      node_locations     = settings.node_locations
      min_count          = settings.min_nodes
      max_count          = settings.max_nodes
      node_count         = (settings.min_nodes == settings.max_nodes) ? settings.min_nodes : null
      autoscaling        = (settings.min_nodes == settings.max_nodes) ? false : true
      local_ssd_count    = settings.local_ssd_count
      disk_size_gb       = settings.os_disk_size
      auto_repair        = (var.kubernetes_channel == "UNSPECIFIED") ? false : true
      auto_upgrade       = (var.kubernetes_channel == "UNSPECIFIED") ? false : true
      preemptible        = false
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      accelerator_count  = settings.accelerator_count
      accelerator_type   = settings.accelerator_type
      initial_node_count = settings.initial_node_count
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    for nodepool, settings in local.node_pools : nodepool => settings.node_labels
  }

  node_pools_taints = {
    for nodepool, settings in local.node_pools : nodepool => [
      for taint in settings.node_taints : {
        key    = split("=", split(":", taint)[0])[0]
        value  = split("=", split(":", taint)[0])[1]
        effect = local.taint_effects[split(":", taint)[1]]
      }
    ]
  }

  depends_on = [module.vpc]
}

module "kubeconfig" {
  source                   = "./modules/kubeconfig"
  prefix                   = var.prefix
  namespace                = "kube-system"
  create_static_kubeconfig = var.create_static_kubeconfig
  cluster_name             = module.gke.name
  cluster_endpoint         = "https://${module.gke.endpoint}"
  cluster_ca_cert          = module.gke.ca_certificate

  depends_on = [module.gke]
}

# Create file based kube config
resource "local_file" "kubeconfig" {
  count                = var.tf_enterprise_integration_enabled ? 0 : 1
  content              = module.kubeconfig.kube_config
  filename             = local.kubeconfig_path
  file_permission      = "0644"
  directory_permission = "0755"
}

# Module Registry - https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/12.0.0/submodules/postgresql
module "postgresql" {
  source     = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version    = "~> 25.2.2"
  project_id = var.project

  for_each = local.postgres_servers != null ? length(local.postgres_servers) != 0 ? local.postgres_servers : {} : {}

  name                 = lower("${var.prefix}-${each.key}-pgsql")
  random_instance_name = true // Need this because of this: https://cloud.google.com/sql/docs/mysql/delete-instance
  zone                 = local.zone

  region            = local.region // regex("^[a-z0-9]*-[a-z0-9]*", var.location)
  availability_type = each.value.availability_type

  deletion_protection = false
  module_depends_on   = [google_service_networking_connection.private_vpc_connection]

  edition = each.value.edition
  tier    = each.value.machine_type

  disk_size = each.value.storage_gb

  enable_default_db        = false
  user_name                = each.value.administrator_login
  user_password            = each.value.administrator_password
  user_labels              = var.tags
  user_deletion_policy     = "ABANDON"
  database_deletion_policy = "ABANDON"
  database_version         = "POSTGRES_${each.value.server_version}"
  database_flags           = values(zipmap(concat(local.base_database_flags[*].name, each.value.database_flags[*].name), concat(local.base_database_flags, each.value.database_flags)))

  backup_configuration = {
    enabled                        = each.value.backups_enabled
    start_time                     = each.value.backups_start_time
    location                       = each.value.backups_location
    point_in_time_recovery_enabled = each.value.backups_point_in_time_recovery_enabled
    retained_backups               = each.value.backup_count
    retention_unit                 = "COUNT"
    transaction_log_retention_days = 1 # Range is 1-7 and should always be at most backup_count - 1 Can never be more than backup_count
  }

  ip_configuration = {
    private_network    = module.vpc.network_self_link
    require_ssl        = each.value.ssl_enforcement_enabled
    allocated_ip_range = null
    ipv4_enabled       = length(local.postgres_public_access_cidrs) > 0 ? true : false
    authorized_networks = [
      for cidr in local.postgres_public_access_cidrs : {
        value = cidr
      }
    ]
  }
}

module "sql_proxy_sa" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 4.4.0"
  count         = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? 1 : 0 : 0
  project_id    = var.project
  prefix        = var.prefix
  names         = ["sql-proxy-sa"]
  project_roles = ["${var.project}=>roles/cloudsql.admin"]
  display_name  = "IAC-managed service account for cluster ${var.prefix} and sql-proxy integration."
}

module "google_netapp" {
  source = "./modules/google_netapp"

  # NetApp Volumes is the only supported zone-redundant RWX storage backend for HA.
  # When storage_type = "ha", NetApp Volumes are always provisioned.
  # For single-zone / standard deployments, use storage_type = "standard" (Filestore).
  count = var.storage_type == "ha" ? 1 : 0

  prefix             = var.prefix
  region             = local.region
  network            = module.vpc.network_name
  netapp_subnet_cidr = var.netapp_subnet_cidr
  service_level      = var.netapp_service_level
  capacity_gib       = var.netapp_capacity_gib
  protocols          = var.netapp_protocols
  volume_path        = "${var.prefix}-${var.netapp_volume_path}"
  allowed_clients    = join(",", [local.gke_subnet_cidr, local.misc_subnet_cidr])
  default_nodepool_locations = var.default_nodepool_locations
  depends_on         = [ module.gke ]

  community_netapp_networking_components_enabled = var.community_netapp_networking_components_enabled
}