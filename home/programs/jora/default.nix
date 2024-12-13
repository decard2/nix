{
  pkgs,
  config,
  ...
}: {
  home.packages = [
    (pkgs.writeScriptBin "jora" ''
      #!${pkgs.bash}/bin/bash
      cd ${config.home.homeDirectory}/nix/home/programs/jora
      nix-shell --run "python src/main.py"
    '')
  ];
}
