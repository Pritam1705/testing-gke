terraform {
  required_version = ">= 1.0, < 1.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    bucket = "apnamart-dev-uat"
    prefix = "env/non-prod/gke/terraform.tfstate"
  }
}
