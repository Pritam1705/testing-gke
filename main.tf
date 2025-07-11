resource "google_container_cluster" "standard" {
  for_each = {
    for k, v in var.clusters : k => v if v.autopilot == false
  }

  name                     = each.value.name
  location                 = each.value.location
  project                  = var.project_id
  network                  = var.network
  subnetwork               = var.subnetwork
  remove_default_node_pool = true
  deletion_protection      = false

  initial_node_count = each.value.initial_node_count

  dynamic "private_cluster_config" {
    for_each = lookup(each.value, "enable_private_nodes", false) ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = false
      master_ipv4_cidr_block  = each.value.master_ipv4_cidr_block
    }
  }
}

resource "google_container_node_pool" "standard_nodepool" {
  for_each = merge([
    for cluster_key, cluster_val in var.clusters : (
      cluster_val.autopilot == false ?
      { for np_key, np_val in lookup(cluster_val, "node_pools", {}) :
        "${cluster_key}-${np_key}" => {
          cluster_key  = cluster_key
          cluster_name = cluster_val.name
          cluster_loc  = cluster_val.location
          np_key       = np_key
          np_val       = np_val
        }
      } : {}
    )
  ]...)

  name       = each.value.np_key
  location   = each.value.cluster_loc
  cluster    = google_container_cluster.standard[each.value.cluster_key].name
  project    = var.project_id
  node_count = each.value.np_val.node_count
  autoscaling {
    min_node_count = each.value.np_val.min_node_count
    max_node_count = each.value.np_val.max_node_count
  }

  node_config {
    machine_type    = each.value.np_val.machine_type
    disk_size_gb    = each.value.np_val.disk_size_gb
    disk_type       = each.value.np_val.disk_type
    image_type      = each.value.np_val.image_type
    service_account = var.use_existing_sa ? var.service_account_email : google_service_account.gke_sa[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    preemptible = lookup(each.value.np_val, "spot", false)
    labels      = lookup(each.value.np_val, "labels", {})

    dynamic "taint" {
      for_each = lookup(each.value.np_val, "taints", [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

resource "google_container_cluster" "autopilot" {
  for_each = {
    for k, v in var.clusters : k => v if v.autopilot == true
  }

  name                = each.value.name
  location            = each.value.location
  project             = var.project_id
  network             = lookup(each.value, "network", var.network)
  subnetwork          = lookup(each.value, "subnetwork", var.subnetwork)
  deletion_protection = false
  enable_autopilot    = true
}

resource "google_service_account" "gke_sa" {
  count        = var.use_existing_sa ? 0 : 1
  account_id   = var.service_account_id
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke_sa_roles" {
  count   = var.use_existing_sa ? 0 : length(var.service_account_roles)
  project = var.project_id
  role    = var.service_account_roles[count.index]
  member  = "serviceAccount:${google_service_account.gke_sa[0].email}"
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account_iam_member" "allow_gke_control_plane" {
  count              = var.use_existing_sa ? 0 : 1
  service_account_id = google_service_account.gke_sa[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_project.current.number}@cloudservices.gserviceaccount.com"
}
