{ inputs, config, pkgs, ... }:
{
  home.packages = with pkgs; [ nixpkgs-fmt ];

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
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "update.mode" = "manual";
    };
  };
}
