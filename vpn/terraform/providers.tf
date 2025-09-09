terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    google = {
      source = "hashicorp/google"
    }
  }
  required_version = ">= 1.2"
}

# Providers
provider "cloudflare" {
  api_token = "bnIqUFEtv-JSS_aOiRk2pjluYX-rGboHxp-iJyQ_"
}
provider "google" {
  project = "rolder-471208"
}
