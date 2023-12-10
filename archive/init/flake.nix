{
  description = "Lemerald";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ self, nixpkgs, home-manager, hyprland, nix-index-database, ... }: {
    nixosConfigurations = {
      lemerald = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
          nix-index-database.nixosModules.nix-index
          hyprland.nixosModules.default
          { programs.hyprland.enable = true; }          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.decard = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }          
        ];
      };
    };
  };
}
