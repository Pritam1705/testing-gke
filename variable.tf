variable "clusters" {
  description = "Map of GKE cluster configurations"
  type = map(object({
    name                   = string
    location               = string
    autopilot              = bool
    enable_private_nodes   = optional(bool, false)
    master_ipv4_cidr_block = optional(string)
    initial_node_count     = optional(number, 1) # ✅ add this as optional with default 1
    node_pools = optional(map(object({
      min_node_count = number
      max_node_count = number
      node_count     = optional(number) # ✅ added here for fixed node count
      machine_type   = string
      disk_size_gb   = number
      disk_type      = string
      image_type     = optional(string) # ✅ Added here for node image type
      spot           = optional(bool, false)
      labels         = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
    })), {})
  }))
}

variable "project_id" {
  type = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "use_existing_sa" {
  description = "Use an existing service account"
  type        = bool
  default     = false
}

variable "service_account_email" {
  type    = string
  default = ""
}

variable "service_account_id" {
  type    = string
  default = "gke-service-account"
}

variable "service_account_roles" {
  type = list(string)
  default = [
    "roles/container.nodeServiceAccount",
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser"
  ]
}
7:39
project_id            = "nw-opstree-dev-landing-zone"
region                = "us-central1"
network               = "default"
subnetwork            = "default"
use_existing_sa       = false
service_account_id    = "gke-sa"
service_account_email = "" # Leave empty if creating a new SA
service_account_roles = [
  "roles/container.nodeServiceAccount",
  "roles/compute.instanceAdmin.v1",
  "roles/iam.serviceAccountUser"
]

clusters = {
  "dev-cluster" = {
    name                   = "dev-cluster"
    location               = "us-central1-a"
    autopilot              = false
    initial_node_count     = 1
    enable_private_nodes   = true
    master_ipv4_cidr_block = "172.16.0.0/28"

    node_pools = {
      "default-pool" = {
        machine_type   = "e2-medium"
        disk_size_gb   = 50
        disk_type      = "pd-standard"
        image_type     = "COS_CONTAINERD" # ✅ Example image type
        min_node_count = 1
        max_node_count = 2
        node_count     = 1 # ✅ added node_count
        spot           = false
        labels         = { env = "dev" }
        taints         = []
      }

      "gpu-pool" = {
        machine_type   = "n1-standard-4"
        disk_size_gb   = 100
        disk_type      = "pd-ssd"
        image_type     = "UBUNTU" # ✅ Example image type
        min_node_count = 0
        max_node_count = 1
        node_count     = 1 # ✅ added node_count
        spot           = true
        labels         = { env = "dev", type = "gpu" }
        taints = [
          {
            key    = "dedicated"
            value  = "gpu"
            effect = "NO_SCHEDULE"
          }
        ]
      }
    }
  }
}
