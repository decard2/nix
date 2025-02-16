{ pkgs, inputs, ... }:
{
  imports = [
    ./zed
    ./roodl.nix
  ];

  programs = {
    git = {
      enable = true;
      userName = "decard";
      userEmail = "mail@decard.space";
    };
  };

  home.packages = with pkgs; [
    lazygit
    inputs.flox.packages.${pkgs.system}.default
  ];
}
