{ pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./theme.nix
    ./hyprland.nix
    ./yofi.nix
    ./hyprpolkitagent.nix
    ./fileAssociations.nix
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
    hyprsunset
    hyprpolkitagent
    yofi
    papirus-icon-theme
    jq
    gtk3
    xdg-utils
  ];
}
