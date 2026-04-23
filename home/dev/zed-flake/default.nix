{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    nixd
    nixfmt
  ];

  programs.zed-editor = {
    enable = true;
    package = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;

    extensions = [
      "html"
      "nix"
      "biome"
      "helm"
      "git-firefly"
      "fish"
      "toml"
      "terraform"
    ];

    userSettings = {
      ui_font_size = 16;
      buffer_font_size = 16;
      agent_buffer_font_size = 16;

      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };

      agent = {
        use_modifier_to_send = true;
      };
      session = {
        trust_all_worktrees = true;
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
        };
      };

      languages = {
        "Nix" = {
          language_servers = [
            "nixd"
            "!nil"
          ];
          formatter = {
            external = {
              command = "nixfmt";
              arguments = [
                "--quiet"
                "--"
              ];
            };
          };
        };
        "JSON" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "JSONC" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "JavaScript" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "TypeScript" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "TSX" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "CSS" = {
          formatter = [
            {
              language_server = {
                name = "biome";
              };
            }
            { code_action = "source.organizeImports.biome"; }
            { code_action = "source.fixAll.biome"; }
          ];
        };
        "Markdown" = {
          format_on_save = "on";
        };
      };

      file_types = {
        "Helm" = [
          "**/templates/**/*.tpl"
          "**/templates/**/*.yaml"
          "**/templates/**/*.yml"
          "**/helmfile.d/**/*.yaml"
          "**/helmfile.d/**/*.yml"
        ];
      };
    };
  };
}
