data "terraform_remote_state" "network_state" {
  backend = "gcs"

  config = {
    bucket = "apnamart-dev-uat"
    prefix = "env/non-prod/network/terraform.tfstate"
  }
}
