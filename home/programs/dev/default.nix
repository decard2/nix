{ pkgs, ... }:
{
  programs =
  {
    git = {
      enable = true;
      userName = "decard";
      userEmail = "mail@decard.space";
    };
  };

    home.packages = with pkgs; [
      lazygit
    ];
}
