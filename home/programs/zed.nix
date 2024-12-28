{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = with pkgs; [
    biome
    nil
    nixd
    alejandra
    bun
    gitui
    pnpm
    moon

    # Rust
    rustc
    cargo
    cargo-edit
    rust-analyzer
    rustfmt

    gcc
    pkg-config
  ];

  programs.git = {
    enable = true;
    userName = "decard";
    userEmail = "mail@decard.space";
  };

  programs.zed-editor = let
    zed = pkgs-unstable.zed-editor;
  in {
    enable = true;
    package = zed;
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
      terminal = {
        env = {
          TERM = "xterm-256color";
          STARSHIP_SHELL = "nu";
        };
        font_family = "FiraCode Nerd Font";
        font_size = 12;
      };
      editor = {
        font_family = "FiraCode Nerd Font";
        font_size = 12;
      };
      code_actions_on_format = {
        "source.fixAll.biome" = true;
        "source.organizeImports.biome" = true;
      };
      lsp = {
        rust-analyzer = {
          binary = {
            path = "/etc/profiles/per-user/decard/bin/rust-analyzer";
            settings = {
              check = {
                command = "clippy";
              };
            };
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
        "Rust" = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "rustfmt";
              arguments = ["--edition" "2021"];
            };
          };
        };
      };
    };
  };
}
