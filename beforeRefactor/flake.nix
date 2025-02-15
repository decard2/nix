{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flox.url = "github:flox/flox/v1.3.11";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      disko,
      home-manager,
      flox,
      nix-ld,
      ...
    }:
    let
      system = "x86_64-linux";
      hostName = "emerald";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          nix-ld.nixosModules.nix-ld
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit
                pkgs
                pkgs-unstable
                flox
                nix-ld
                ;
            };
            home-manager.users.decard = import ./home;
          }
        ];
        specialArgs = { inherit pkgs-unstable; };
      };

      devShells.${system}.default = pkgs.mkShell { };
    };
}
