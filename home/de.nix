{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    tofi
    pavucontrol
    brightnessctl
    polkit-kde-agent
    xdg-desktop-portal-hyprland
  ];  

  /* gtk = {
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  }; */
  
/*   qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Breeze-Dark";
  qt.style.package = pkgs.libsForQt5.breeze-gtk; */
  
  services.dunst = {
    enable = true;
    settings = {
      global = {
        frame_color = "#e5e9f0";
        separator_color = "#e5e9f0";
      };
      base16_low = {
        msg_urgency = "low";
        background = "#3b4252";
        foreground = "#4c566a";
      };
      base16_normal = {
        msg_urgency = "normal";
        background = "#434c5e";
        foreground = "#e5e9f0";
      };
      base16_critical = {
        msg_urgency = "critical";
        background = "#bf616a";
        foreground = "#eceff4";
      };
    };
  };

/*   home.pointerCursor = {
    size = 32;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
  }; */
}
