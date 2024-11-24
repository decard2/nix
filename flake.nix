{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, disko, ... }:
     let
       system = "x86_64-linux";
       hostName = "emerald";
     in
     {
       nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
         inherit system;
         modules = [
           ./nixos/hardware-configuration.nix
           ./nixos/disko.nix
           disko.nixosModules.disko
           ({ pkgs, ... }: {
             boot.loader = {
               systemd-boot.enable = true;
               efi.canTouchEfiVariables = true;
             };
             networking = { inherit hostName; };
             environment.systemPackages = with pkgs; [
               git
             ];
             system.stateVersion = "24.05";
           })
         ];
       };
     };
}
