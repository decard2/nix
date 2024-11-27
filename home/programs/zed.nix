{pkgs, ...}: {
  home.packages = with pkgs; [
    zed-editor
    rust-analyzer
    biome
    nil
    nixd
    alejandra
    bun
    gitui
  ];

  programs.git = {
    enable = true;
    userName = "decard";
    userEmail = "mail@decard.space";
  };

  home.file.".config/zed/settings.json".text = ''
    {
      "theme": "One Dark",
      "vim_mode": false,
      "auto_install_extensions": {
        "nix": true,
        "biome": true
      },
      "features": {
        "inline_completion_provider": "none"
       },
      "assistant": {
        "default_model": {
          "provider": "zed.dev",
          "model": "claude-3-5-sonnet-latest"
        },
        "version": "2"
      },
      "lsp": {
        "rust-analyzer": {
          "binary": {
            "path_lookup": true
          }
        },
        "nil": {
          "binary": {
            "path_lookup": true
          },
          "settings": {
            "formatting": {
              "command": ["alejandra"]
            }
          }
        },
        "biome": {
          "binary": {
            "path": "/etc/profiles/per-user/decard/bin/biome",
            "arguments": ["lsp-proxy"]
          }
        },
      },
      "formatter": {
    		"language_server": {
    			"name": "biome"
    		}
    	},
      "language_servers": [ "!package-version-server", "..." ]
    }
  '';
}
