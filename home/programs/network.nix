{ config, pkgs, ... }: {
  home.file.".config/wireguard/" = {
    recursive = true;
    source = ./wireguard;
  };

  # Автоматический импорт конфига при первом запуске
  systemd.user.services.import-wireguard = {
    Unit = {
      Description = "Import WireGuard configuration";
      After = "network.target";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.networkmanager}/bin/nmcli connection import type wireguard file %h/.config/wireguard/vpn.conf";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
