{ inputs, config, pkgs, ... }:
{
  home.packages = with pkgs; [ nixpkgs-fmt ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      davidanson.vscode-markdownlint
      jnoortheen.nix-ide
      chenglou92.rescript-vscode
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
    };
  };
}
