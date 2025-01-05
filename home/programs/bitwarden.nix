{ pkgs, ... }: {
  home.packages = with pkgs; [ rbw pinentry ];

  home.file.".config/rbw/config.json".text = ''
    {
      "email": "mail@decard.space",
      "sso_id":null,
      "base_url":"https://vault.decard.space",
      "identity_url":null,
      "ui_url":null,
      "notifications_url":null,
      "lock_timeout":2592000,
      "sync_interval":3600,
      "pinentry":"pinentry",
      "client_cert_path":null
    }
  '';
}
