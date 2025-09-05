module "cfke_connected_fleet" {
  source               = "registry.terraform.io/cloudfleetai/cfke-connected-fleet/aws"
  version              = "~> 0.1.0"
  control_plane_region = "europe-central-1a"
  cluster_id           = "399e71c0-734b-4444-ac66-c38c81c2881c"
}
