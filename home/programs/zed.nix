{ pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
    bun
    gitui

    # Nix
    nixd
    nixfmt-rfc-style

    # Helm
    helm-ls
    yamlfmt
  ];

  programs.git = {
    enable = true;
    userName = "decard";
    userEmail = "mail@decard.space";
  };

  programs.zed-editor =
    let
      zed = pkgs-unstable.zed-editor;
    in
    {
      enable = true;
      package = zed;
      extensions = [
        "nix"
        "nu"
        "biome"
        "helm"
      ];
      userSettings = {
        hour_format = "hour24";
        auto_update = false;
        theme = "One Dark";

        language_models = {
          openai = {
            version = "1";
            available_models = [
              {
                name = "deepseek-chat";
                max_tokens = 128000;
              }
              # {
              #   name = "deepseek-reasoner";
              #   max_tokens = 128000;
              # }
            ];
            api_url = "https://api.deepseek.com/v1";
          };
        };

        assistant = {
          version = "2";

          default_model = {
            provider = "openai";
            model = "deepseek-chat";
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
        formatter = {
          language_server = {
            name = "biome";
          };
        };
        code_actions_on_format = {
          "source.fixAll.biome" = true;
          "source.organizeImports.biome" = true;
        };
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
          YAML = {
            formatter = {
              external = {
                command = "yamlfmt";
                arguments = [ "-in" ];
              };
            };
          };
          Helm = {
            formatter = {
              external = {
                command = "yamlfmt";
                arguments = [ "-in" ];
              };
            };
          };
        };
        file_types = {
          Helm = [
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
