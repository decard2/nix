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
        warsaw = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "warsaw";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "pl.rolder.net";
              selfstealTemplate = "10gag";
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

        helsinki = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "helsinki";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
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

        helsinkiGcore = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "helsinkiGcore";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "fi2.rolder.net";
              selfstealTemplate = "games-site";
              useDHCP = true;
              isGCP = false;
              diskDevice = "/dev/sda";
            };
            inherit selfsteal-templates;
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        frankfurt = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "frankfurt";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "de.rolder.net";
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
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
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
