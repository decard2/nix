{
  description = "NixOS configuration for servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selfsteal-templates = {
      url = "github:DigneZzZ/remnawave-scripts";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      disko,
      selfsteal-templates,
      ...
    }:
    {
      nixosConfigurations = {
helsinki = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "helsinki";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "fi.rolder.net";
              selfstealTemplate = "games-site";
              isGCP = true;
            };
            inherit selfsteal-templates;
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        helsinkiStandard = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "helsinkiStandard";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "fistandard.rolder.net";
              selfstealTemplate = "games-site";
              isGCP = true;
            };
            inherit selfsteal-templates;
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        remnapanel = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "remnapanel";
              containers = [ "remnapanel" ];
              isGCP = true;
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };
      };
    };
}
