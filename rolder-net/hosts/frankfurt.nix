# Frankfurt host-specific configuration
# This module contains settings unique to the frankfurt server
{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}:

{
  # Frankfurt-specific network settings
  # Additional firewall rules if needed for this host
  # networking.firewall.allowedTCPPorts = [ ];

  # Frankfurt-specific services or configurations
  # Can add host-specific overrides here

  # Example: Frankfurt-specific environment variables
  # environment.variables = {
  #   DATACENTER = "Frankfurt";
  # };

  # Host-specific systemd services if needed
  # systemd.services.frankfurt-specific = {
  #   enable = true;
  #   description = "Frankfurt specific service";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.coreutils}/bin/echo 'Frankfurt host initialized'";
  #   };
  #   wantedBy = [ "multi-user.target" ];
  # };
}
