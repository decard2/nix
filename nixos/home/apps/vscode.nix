{ inputs, config, pkgs, ... }:
{
  home.packages = with pkgs; [ nixpkgs-fmt ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      davidanson.vscode-markdownlint
      jnoortheen.nix-ide      
    ];
    userSettings = {
      "window.titleBarStyle" = "custom";
      "editor.fontSize" = 16;
      "workbench.activityBar.location" = "top";
      "explorer.confirmDelete" = false;
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "update.mode" = "manual";
      "workbench.startupEditor" = "none";
      "workbench.colorTheme" = "Default Dark Modern";
      "files.exclude" = {
        "**/archive" = true;
      };
      "markdownlint.config" = {
        "MD024" = {
          "siblings_only" = true;
        };
      };
      "rescript.settings.allowBuiltInFormatter" = true;
      "cssVariables.lookupFiles" = [
        "**/*.css"
        "**/*.scss"
        "**/*.sass"
        "**/*.less"
        "node_modules/@mantine/core/styles.css"
      ];
    };
  };
}
