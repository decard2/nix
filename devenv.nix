{ pkgs, ... }:

{
  packages = with pkgs; [
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
  ];

  languages.terraform.enable = true;
}
