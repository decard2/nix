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
        frankfurt = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "frankfurt";
              serverIP = "37.221.125.150";
              gateway = "37.221.125.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
              containers = [ "remnanode" ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        bucharest = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "bucharest";
              serverIP = "45.67.34.30";
              gateway = "45.67.34.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [ "remnanode" ];
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        stockholm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "stockholm";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/";
              containers = [
                "remnanode"
                "selfsteal"
              ];
              selfstealDomain = "sw.rolder.net";
              selfstealTemplate = "10gag";
              # Enable GCP features
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
              containers = [ "remnanode" ];
              # Enable GCP features
              isGCP = true;
            };
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
              # serverIP = "91.207.183.149";
              # gateway = "91.207.183.1";
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
