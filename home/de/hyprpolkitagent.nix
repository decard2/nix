{
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Agent";
      PartOf = [ "uwsm-session.target" ];
      After = [ "uwsm-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };

    Install = {
      WantedBy = [ "uwsm-session.target" ];
    };
  };
}
