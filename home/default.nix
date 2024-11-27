{...}: {
  imports = [
    ./programs
    ./packages.nix
    ./fonts.nix
    ./environment.nix
    ./theme.nix
  ];

  home = {
    username = "decard";
    homeDirectory = "/home/decard";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
}
