{ pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./theme.nix
    ./hyprland.nix
    ./hyprlauncher.nix
    ./hyprpolkitagent.nix
    ./mako.nix
    ./fileAssociations.nix
  ];

  dconf.enable = true;

  home.packages = with pkgs; [
    qt6Packages.qt6ct
    bibata-cursors
    thunar
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
    wlsunset
    hyprsunset
    hyprpolkitagent
    papirus-icon-theme
    gtk3
    xdg-utils
  ];
}
