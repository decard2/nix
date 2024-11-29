{pkgs, ...}: {
  home.packages = with pkgs; [
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

  programs.zed-editor = {
    enable = true;
    extensions = ["nu"];
    userSettings = {
      hour_format = "hour24";
      auto_update = false;
      theme = "One Dark";
      assistant = {
        enabled = true;
        version = "2";
        default_open_ai_model = null;

        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
      };
      features = {
        inline_completion_provider = "none";
      };
      code_actions_on_format = {
        "source.fixAll.biome" = true;
        "source.organizeImports.biome" = true;
      };
      lsp = {
        rust-analyzer = {
          binary = {
            path_lookup = true;
          };
        };
        nix = {
          binary = {
            path_lookup = true;
          };
        };
        nil = {
          binary = {
            path_lookup = true;
          };
          settings = {
            formatting = {
              command = ["alejandra"];
            };
          };
        };
        biome = {
          enable = true;
          binary = {
            path = "/etc/profiles/per-user/decard/bin/biome";
            arguments = ["lsp-proxy"];
          };
        };
      };
      languages = {
        "JavaScript" = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "biome";
              arguments = ["format" "--stdin-file-path" "{buffer_path}"];
            };
          };
        };
        "TypeScript" = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "biome";
              arguments = ["format" "--stdin-file-path" "{buffer_path}"];
            };
          };
        };
        "TSX" = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "biome";
              arguments = ["format" "--stdin-file-path" "{buffer_path}"];
            };
          };
        };
        "JSON" = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "biome";
              arguments = ["format" "--stdin-file-path" "{buffer_path}"];
            };
          };
        };
      };
    };
  };
}
