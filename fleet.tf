terraform {
    required_providers {
        cloudfleet = {
            source = "terraform.cloudfleet.ai/cloudfleet/cloudfleet"
        }
    }
}

variable "cfke_control_plane_region" {
    description = "CFKE control plane region where the cluster is deployed"
    type        = string
    default     = "europe-central-1a"
}

variable "gcp_project" {
    type        = string
    description = "GCP project ID where CFKE nodes will be provisioned"
}

variable "hetzner_api_key" {
    description = "API key for Hetzner Cloud"
    type        = string
    sensitive   = true
}

variable "aws_region" {
    description = "AWS region where CFKE nodes will be provisioned"
    type        = string
    default     = "eu-central-1"
}

variable "aws_profile" {
    description = "AWS profile to use authenticate with AWS"
    type        = string
    default     = "default"
}

variable "hetzner_api_key" {
    description = "API key for Hetzner Cloud"
    type        = string
    sensitive   = true
}

provider "aws" {
    region  = var.aws_region
    profile = var.aws_profile
}

provider "cloudfleet" {
    profile = "default"
}

resource "cloudfleet_cfke_cluster" "cfke_test" {
    name   = "cfke-test"
    region = var.cfke_control_plane_region
    tier   = "basic"
}

resource "google_project_iam_custom_role" "cfke_node_autoprovisioner" {
    project = var.gcp_project
    permissions = [
        "compute.instances.create",
        "compute.instances.delete",
        "compute.instances.get",
        "compute.instances.list",
        "compute.disks.create",
        "compute.subnetworks.use",
        "compute.subnetworks.useExternalIp",
        "compute.instances.setMetadata",
        "compute.instances.setTags",
        "compute.instances.setLabels"
    ]
    role_id = "cfke.nodeAutoprovisioner"
    title   = "CFKE Node-autoprovisioner"
}

locals {
    cfke_gcp_project = {
        "northamerica-central-1" = "89014267864"
        "europe-central-1a" = "207152264238"
    }
}

resource "google_project_iam_binding" "gcp_project_binding" {
    project = var.gcp_project
    role    = google_project_iam_custom_role.cfke_node_autoprovisioner.id
    members = [
        "principal://iam.googleapis.com/projects/${local.cfke_gcp_project[cloudfleet_cfke_cluster.cfke_test.region]}/locations/global/workloadIdentityPools/cfke/subject/${cloudfleet_cfke_cluster.hetzner_test.id}"
    ]
}

module "cfke_connected_fleet" {
    source               = "registry.terraform.io/cloudfleetai/cfke-connected-fleet/aws"
    version              = "~> 0.1.0"
    control_plane_region = cloudfleet_cfke_cluster.cfke_test.region
    cluster_id           = cloudfleet_cfke_cluster.cfke_test.id
}

resource "cloudfleet_cfke_fleet" "fleet" {

    depends_on = [
        google_project_iam_binding.gcp_project_binding
    ]

    cluster_id = cloudfleet_cfke_cluster.cfke_test.id
    name       = "cfke-multi-cloud-fleet"

    limits {
        cpu = 24
    }

    hetzner {
        api_key = var.hetzner_api_key
    }

    aws {
        role_arn = module.cfke_connected_fleet.fleet_arn
    }

    gcp {
        project_id = var.gcp_project
    }
}
