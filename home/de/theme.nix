{ pkgs, ... }:
{
  home = {
    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };

    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "20";
      MOZ_USE_XINPUT2 = "1";
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";
      DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
      ADW_DISABLE_PORTAL = "1";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita";
        color-scheme = "prefer-dark";
      };
    };
  };
}
