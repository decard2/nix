{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];

  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        ui = {
          skin = "gruvbox-dark"; # Тема в стиле gruvbox
          headless = true;
          logoless = false;
        };
        thresholds = {
          memory = {
            critical = 90;
            warn = 80;
          };
        };
      };
    };
  };
}
