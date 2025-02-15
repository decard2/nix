{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k0sctl
    k9s # Крутой TUI клиент для kubectl
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
      };
    };
  };
}
