{
  description = "Decard NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flox.url = "github:flox/flox";

    yandex-browser.url = "github:miuirussia/yandex-browser.nix";
    yandex-browser.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      disko,
      home-manager,
      nixos-generators,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.emerald = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./system
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager

          {
            nixpkgs.config.allowUnfree = true;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.decard = import ./home;
          }
        ];
      };

      # ISO образ для автоустановки
      packages.${system} = {
        default = nixos-generators.nixosGenerate {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./system/installer.nix
          ];
          format = "iso";
        };
      };
    };
}
