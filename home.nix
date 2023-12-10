{ inputs, config, pkgs, ... }:
{
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hypr
  ];

  home.packages = with pkgs; [
    #cli    
    zsh
    oh-my-zsh
    git
    kitty
    btop
    shadowsocks-rust
    comma
    #de
    tofi
    pavucontrol
    #apps
    firefox
    telegram-desktop
    nixpkgs-fmt
    #system
    pulseaudio
    brightnessctl
    polkit-kde-agent
    xdg-desktop-portal-hyprland
    libsecret
  ];

  home.username = "decard";
  home.homeDirectory = "/home/decard";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    theme = {
      name = "Breeze-Dark";
      package = pkgs.libsForQt5.breeze-gtk;
    };
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
  };

  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Breeze-Dark";
  qt.style.package = pkgs.libsForQt5.breeze-gtk;

  programs.kitty = {
    enable = true;
    settings = {
      font_size = 16;
      background_opacity = "0.75";
    };
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "refined";
      plugins = [ "kubectl" "helm" ];
    };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      yzhang.markdown-all-in-one
      jnoortheen.nix-ide
    ];
    userSettings = {
      "window.titleBarStyle" = "custom";
      "editor.fontSize" = 16;
      "workbench.activityBar.location" = "top";
      "explorer.confirmDelete" = false;
    };
  };

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

  home.pointerCursor = {
    size = 32;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
  };
}
