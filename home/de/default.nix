{ pkgs, ... }:
{
  imports = [
    ./fonts.nix
    ./theme.nix
    ./hyprland.nix
    ./yofi.nix
    ./hyprpolkitagent.nix
  ];

  home.packages = with pkgs; [
    qt6ct
    bibata-cursors
    xfce.thunar
    file-roller
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
  ];
}
