module "gke" {
  source     = "git::https://github.com/Pritam1705/testing-gke.git"
  project_id = var.project_id
  network    = data.terraform_remote_state.network_state.outputs.vpc_id
  subnetwork = values({
    for k, v in data.terraform_remote_state.network_state.outputs.subnet_ids :
    k => v if can(regex("application-subnet", k))
  })[0]
  use_existing_sa       = var.use_existing_sa
  service_account_email = var.service_account_email
  service_account_id    = var.service_account_id
  service_account_roles = var.service_account_roles
  clusters              = var.clusters
}




