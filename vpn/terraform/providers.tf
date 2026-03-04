terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    google = {
      source = "hashicorp/google"
    }
    gcore = {
      source  = "G-Core/gcore"
      version = ">= 0.3.65"
    }
  }
  required_version = ">= 1.2"
}

# Providers
provider "cloudflare" {
  api_token = "bnIqUFEtv-JSS_aOiRk2pjluYX-rGboHxp-iJyQ_"
}
provider "google" {
  # project = "rolder-471208"
  project = "rolder-474107"
}

provider "gcore" {
  permanent_api_token = "28381$32aa103505873a264f585c44fa43e1269970fff3bce66fc1e9739561e9d37d3c2087c744817c638aa4fdb1a4e4858553f887dcad135b2f7ec88d8bf0a64425b5"
}
