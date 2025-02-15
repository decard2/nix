{ pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
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
        "fish"
        "biome"
        "helm"
      ];
      userSettings = {
        hour_format = "hour24";
        auto_update = false;
        theme = "One Dark";

        language_models = {
          deepseek = {
            available_models = [
              {
                name = "deepseek-chat";
                display_name = "DeepSeek Chat";
                max_tokens = 64000;
              }
              {
                name = "deepseek-reasoner";
                display_name = "DeepSeek Reasoner";
                max_tokens = 64000;
              }
            ];
            api_url = "https://api.deepseek.com";
          };
        };

        assistant = {
          version = "2";

          default_model = {
            # provider = "openai";
            # model = "deepseek-chat";
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
            STARSHIP_SHELL = "fish";
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
