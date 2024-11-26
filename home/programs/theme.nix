{pkgs, ...}: {
  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    libsForQt5.qt5ct
    qt6ct
    libsForQt5.qtstyleplugins
    libsForQt5.qtstyleplugin-kvantum
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
    # Для Qt6 приложений
    QT_STYLE_OVERRIDE = "kvantum";
    XCURSOR_THEME = "Adwaita";
  };
}
