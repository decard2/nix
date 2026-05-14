{
  services.mako = {
    enable = true;
    settings = {
      font = "FiraCode Nerd Font 11";
      default-timeout = 5000;
      border-radius = 8;
      border-size = 1;
      padding = "12";
      margin = "12";
      max-icon-size = 48;

      background-color = "#1f2430";
      text-color = "#cbccc6";
      border-color = "#33ccff";
      progress-color = "over #33ccff44";

      "urgency=high" = {
        border-color = "#ff3333";
        default-timeout = 0;
      };
    };
  };
}
