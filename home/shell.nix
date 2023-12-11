{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    pciutils    
    neofetch
  ];
  programs.git = {
    enable = true;
    userName  = "Decard";
    userEmail = "mail@dayreon.ru";
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "refined";
      plugins = [ "kubectl" "helm" ];
    };
  };
  programs.kitty = {
    enable = true;
    settings = {
      font_size = 16;
      background_opacity = "0.75";
    };
  };
}
