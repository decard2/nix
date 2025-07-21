{ pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./theme.nix
    ./hyprland.nix
    ./yofi.nix
    ./hyprpolkitagent.nix
    ./fileAssociations.nix
    ./hyprsunset.nix
  ];

  dconf.enable = true;

  home.packages = with pkgs; [
    qt6ct
    bibata-cursors
    xfce.thunar
    file-roller
    alsa-lib
    playerctl
    pamixer
    pavucontrol
    wireplumber
    brightnessctl
    hyprshot
    wl-clipboard
    hyprcursor
    # hyprsunset - заменен на кастомную версию 0.3.0 в hyprsunset.nix
    hyprpolkitagent
    yofi
    papirus-icon-theme
    gtk3
    xdg-utils
  ];
}
