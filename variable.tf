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
