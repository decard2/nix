{
  description = "Decard NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flox.url = "github:flox/flox";
  };

  outputs =
    inputs@{
      nixpkgs,
      disko,
      home-manager,
      flox,
      ...
    }:
    {
      nixosConfigurations.emerald = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./system
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager

          {
            nixpkgs.config.allowUnfree = true;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.decard = import ./home;
          }
        ];
      };
    };
}
