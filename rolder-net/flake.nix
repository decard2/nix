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
            hostname = "frankfurt";
            rolderPassword = "$6$5VyQ15pyF.cRI95q$CN.UM.kgGa6twTEHFn4fIz6NNVpMWYzbv9J/2UQzJaRN3zr7B74PfZFx7LBbKNUBw9DmR5ApMy.wbF/uMXboa/"; # Htvyfdfht
            serverIP = "37.221.125.150";
            gateway = "37.221.125.1";
          };
          modules = [
            disko.nixosModules.disko
            ./configuration.nix
            ./disk-config.nix
            ./hardware/frankfurt.nix
          ];
        };
      };
    };
}
