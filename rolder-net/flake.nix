{
  description = "NixOS configuration for servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, disko, ... }:
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
              nodeDomain = "n1.rolder.net";
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
              nodeDomain = "n2.rolder.net";
            };
          };
          modules = [
            disko.nixosModules.disko
            ./common.nix
            ./disk-config.nix
          ];
        };

        panel = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            hostConfig = {
              hostname = "panel";
              serverIP = "91.207.183.149";
              gateway = "91.207.183.1";
              rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
              containers = [ "remnapanel" ];
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
