{
  pkgs,
  inputs,
  ...
}:
let
  floxPkg = inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.flox;
  claudeAcpFlox = pkgs.writeShellScript "claude-acp-flox" ''
    set -eu
    cwd="''${PWD:-$(pwd)}"
    prefix="$HOME/.local/share/zed/external_agents/registry/npx/claude-acp"
    cache="$HOME/.local/share/zed/node/cache"
    mkdir -p "$prefix" "$cache"
    acp_cmd="${pkgs.nodejs_22}/bin/npm --prefix $prefix exec --cache=$cache --yes -- @agentclientprotocol/claude-agent-acp@latest"
    if [ -d "$cwd/.flox" ]; then
      exec ${floxPkg}/bin/flox activate -d "$cwd" -c "$acp_cmd"
    else
      exec sh -c "$acp_cmd"
    fi
  '';
in
{
  home.packages = with pkgs; [
    nixd
    nixfmt
  ];

  programs.zed-editor = {
    enable = true;
    package = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;
    mutableUserSettings = false;

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
      ui_font_size = 15;
      buffer_font_size = 15;
      agent_buffer_font_size = 15;
      agent_ui_font_size = 20.0;

      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Ayu Dark";
      };

      agent = {
        use_modifier_to_send = true;
      };
      load_direnv = "shell_hook";
      session = {
        trust_all_worktrees = true;
      };
      agent_servers = {
        claude-acp = {
          type = "custom";
          command = toString claudeAcpFlox;
          args = [ ];
          env = { };
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
