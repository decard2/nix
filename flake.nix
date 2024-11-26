{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nur.url = "github:nix-community/NUR";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    nur,
    disko,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    hostName = "emerald";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [nur.overlay];
    };
  in {
    nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./nixos/configuration.nix
        disko.nixosModules.disko
      ];
    };

    homeConfigurations.decard = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [./home];
      # Если нужны какие-то специальные параметры из NUR или других источников
      extraSpecialArgs = {inherit pkgs;};
    };
  };
}
