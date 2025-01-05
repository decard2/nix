{ pkgs, ... }: {
  programs.nushell = {
    enable = true;

    # Базовые настройки
    extraConfig = ''
      $env.EDITOR = 'zeditor'
      $env.VISUAL = 'zeditor'
      $env.TERM = 'xterm-color'

      # Wayland specific
      $env.XDG_SESSION_TYPE = 'wayland'
      $env.XDG_CURRENT_DESKTOP = 'Hyprland'
      $env.XDG_SESSION_DESKTOP = 'Hyprland'

      # Настройки через config
      $env.config = {
        show_banner: false
      }

      # Автодополнение
      $env.PATH = ($env.PATH | split row (char esep) | prepend "/home/decard/.config/carapace/bin")

      def --env get-env [name] { $env | get $name }
      def --env set-env [name, value] { load-env { $name: $value } }
      def --env unset-env [name] { hide-env $name }

      let carapace_completer = {|spans|
        # if the current command is an alias, get it's expansion
        let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)

        # overwrite
        let spans = (if $expanded_alias != null  {
          # put the first word of the expanded alias first in the span
          $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
        } else {
          $spans
        })

        carapace $spans.0 nushell ...$spans
        | from json
      }

      mut current = (($env | default {} config).config | default {} completions)
      $current.completions = ($current.completions | default {} external)
      $current.completions.external = ($current.completions.external
      | default true enable
      | default $carapace_completer completer)

      $env.config = $current

      # Автозапуск Hyprland в TTY1
      let display = ($env | get -i DISPLAY | default "")
      let wayland_display = ($env | get -i WAYLAND_DISPLAY | default "")

      if ($display == "") and ($wayland_display == "") {
          try {
              if (uwsm check may-start | complete).exit_code == 0 {
                  exec uwsm start hyprland-uwsm.desktop
                  exit
              }
          } catch {
              null
          }
      }

      # Правильный запуск bash
      def --env bash [] {
        ^/run/current-system/sw/bin/bash --rcfile /etc/profile
      }

      # Интеграция direnv через хуки
      $env.config = {
        hooks: {
          pre_prompt: [{ ||
            if (which direnv | is-empty) {
              return
            }

            direnv export json | from json | default {} | load-env
            if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
              $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
            }
          }]
        }
      }

      # Добавляем команды rbw
      def bwf [query: string] {
        rbw list | lines | where $it =~ $query
      }

      def bwp [name: string] {
        rbw get $name | wl-copy
        echo "Пароль в буфере, братишка! Через 15 сек сам очистится 👊"
      }

      def bwu [name: string] {
        rbw get --full $name | from json | get username
      }
    '';

    # Алиасы для удобства
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      ".." = "cd ..";
      "..." = "cd ../..";
      c = "clear";

      nrb = "sudo nixos-rebuild switch --flake .#emerald";
      nup = "nix flake update";
      nd = "nvd diff /run/booted-system/ /run/current-system/";
      g = "gitui";
      bch = "biome check --write .";

      # Bun алиасы
      bun = "bun";
      ba = "bun add";
      bad = "bun add --dev";
      brm = "bun remove";
      bin = "bun install";
      bga = "bun add -g";
      bgls = "bun pm ls -g";
      bgrm = "bun remove -g";

      # Запуск скриптов
      br = "bun run";
      bx = "bun x";

      # Управление зависимостями
      bu = "bun update";
      bout = "bun outdated";
      bup = "bun upgrade";

      # Для разработки
      bd = "bun dev";
      bs = "bun start";
      bt = "bun test";
      bb = "bun build";

      # Очистка
      bclean = "bun clean";

      # PNPM алиасы
      pn = "pnpm";
      pnp = "pnpm publish";
      pin = "pnpm install";
      pa = "pnpm add";
      pad = "pnpm add --save-dev";
      pnrm = "pnpm remove";
      pnx = "pnpm dlx";
      pnst = "pnpm start";
      pnt = "pnpm test";
      pr = "pnpm run";
      pnb = "pnpm build";
      pnd = "pnpm dev";
      pnc = "pnpm create";
      pno = "pnpm outdated";
      pnu = "pnpm update";
      pngi = "pnpm install -g";
      pnga = "pnpm add -g";
      pngrm = "pnpm remove -g";
      pnout = "pnpm outdated";

      # Helm алиасы
      h = "helm";
      hi = "helm install";
      hd = "helm delete";
      hl = "helm list";
      hls = "helm list";
      hg = "helm get";
      hgv = "helm get values";
      hgh = "helm get hooks";
      hgm = "helm get manifest";
      hgn = "helm get notes";
      hr = "helm repo";
      hra = "helm repo add";
      hrl = "helm repo list";
      hru = "helm repo update";
      hrm = "helm repo remove";
      hs = "helm search";
      hsr = "helm search repo";
      hsh = "helm search hub";
      ht = "helm template";
      hu = "helm upgrade";
      hh = "helm history";
      hf = "helm fetch";
      hdp = "helm dependency";
      hdpu = "helm dependency update";

      # Kubectl алиасы
      k = "kubectl";
      kaf = "kubectl apply -f";
      keti = "kubectl exec -ti";
      kg = "kubectl get";
      kgpo = "kubectl get pods";
      kgdep = "kubectl get deployment";
      kgsvc = "kubectl get service";
      kging = "kubectl get ingress";
      kgcm = "kubectl get configmap";
      kgsec = "kubectl get secret";
      kgno = "kubectl get nodes";
      kgns = "kubectl get namespaces";
      kd = "kubectl describe";
      kdpo = "kubectl describe pod";
      kddep = "kubectl describe deployment";
      kdsvc = "kubectl describe service";
      kding = "kubectl describe ingress";
      kdcm = "kubectl describe configmap";
      kdsec = "kubectl describe secret";
      kdno = "kubectl describe node";
      kdns = "kubectl describe namespace";
      kl = "kubectl logs";
      klf = "kubectl logs -f";
      kcp = "kubectl cp";
      kex = "kubectl exec -it";
      kdel = "kubectl delete";
      kdelp = "kubectl delete pod";
      kdeld = "kubectl delete deployment";
      kdels = "kubectl delete service";
      kdeli = "kubectl delete ingress";
      kdelc = "kubectl delete configmap";
      kdelsc = "kubectl delete secret";
      kdelns = "kubectl delete namespace";
      kp = "kubectl proxy";
      kpf = "kubectl port-forward";
      kgpoa = "kubectl get pods --all-namespaces";
      kgpow = "kubectl get pods -o wide";
      kgpoaw = "kubectl get pods --all-namespaces -o wide";
      kns = "kubectl config set-context --current --namespace";
      kctx = "kubectl config use-context";
      kgctx = "kubectl config get-contexts";

      # Docker алиасы
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";
      dl = "docker logs";
      dlf = "docker logs -f";
      dst = "docker stats";
      dip = "docker inspect";
      drm = "docker rm";
      drmi = "docker rmi";
      dpr = "docker prune";
      dstp = "docker stop";
      drs = "docker restart";

      # Docker Compose алиасы
      dcu = "docker-compose up";
      dcud = "docker-compose up -d";
      dcd = "docker-compose down";
      dcr = "docker-compose restart";
      dcl = "docker-compose logs";
      dclf = "docker-compose logs -f";
      dcps = "docker-compose ps";
      dcpull = "docker-compose pull";

      # Lazydocker алиас
      lzd = "lazydocker";
    };
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = builtins.fromTOML ''
      "$schema" = 'https://starship.rs/config-schema.json'

      format = """
      [](bg:color_darkgreen fg:color_darkgreen)\
      $directory\
      [](fg:color_darkgreen bg:color_green)\
      $git_branch\
      $git_status\
      [](fg:color_green bg:color_blue)\
      $c\
      $rust\
      $golang\
      $nodejs\
      $php\
      $java\
      $kotlin\
      $haskell\
      $python\
      [](fg:color_blue bg:color_bg3)\
      $docker_context\
      $conda\
      [](fg:color_bg3 bg:color_bg1)\
      $time\
      [ ](fg:color_bg1)\
      $line_break$character"""

      palette = 'gruvbox_dark'

      [palettes.gruvbox_dark]
      color_fg0 = '#fbf1c7'
      color_bg1 = '#3c3836'
      color_bg3 = '#665c54'
      color_blue = '#458588'
      color_aqua = '#689d6a'
      color_green = '#325e3e'
      color_darkgreen = '#26472f'
      color_orange = '#d65d0e'
      color_purple = '#b16286'
      color_red = '#cc241d'
      color_yellow = '#d79921'

      [os]
      disabled = false
      style = "bg:color_orange fg:color_fg0"

      [os.symbols]
      Windows = "󰍲"
      Ubuntu = "󰕈"
      SUSE = ""
      Raspbian = "󰐿"
      Mint = "󰣭"
      Macos = "󰀵"
      Manjaro = ""
      Linux = "󰌽"
      Gentoo = "󰣨"
      Fedora = "󰣛"
      Alpine = ""
      Amazon = ""
      Android = ""
      Arch = "󰣇"
      Artix = "󰣇"
      EndeavourOS = ""
      CentOS = ""
      Debian = "󰣚"
      Redhat = "󱄛"
      RedHatEnterprise = "󱄛"
      Pop = ""

      [username]
      show_always = true
      style_user = "bg:color_orange fg:color_fg0"
      style_root = "bg:color_orange fg:color_fg0"
      format = '[ $user ]($style)'

      [directory]
      style = "fg:color_fg0 bg:color_darkgreen"
      format = "[ $path ]($style)"
      truncation_length = 3
      truncation_symbol = "…/"

      [directory.substitutions]
      "Documents" = "󰈙 "
      "Downloads" = " "
      "Music" = "󰝚 "
      "Pictures" = " "
      "Developer" = "󰲋 "

      [git_branch]
      symbol = ""
      style = "bg:color_green"
      format = '[[ $symbol $branch ](fg:color_fg0 bg:color_green)]($style)'

      [git_status]
      style = "bg:color_green"
      format = '[[($all_status$ahead_behind )](fg:color_fg0 bg:color_green)]($style)'

      [nodejs]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [c]
      symbol = " "
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [rust]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [golang]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [php]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [java]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [kotlin]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [haskell]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [python]
      symbol = ""
      style = "bg:color_blue"
      format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

      [docker_context]
      symbol = ""
      style = "bg:color_bg3"
      format = '[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)'

      [conda]
      style = "bg:color_bg3"
      format = '[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)'

      [time]
      disabled = false
      time_format = "%R"
      style = "bg:color_bg1"
      format = '[[  $time ](fg:color_fg0 bg:color_bg1)]($style)'

      [line_break]
      disabled = false

      [character]
      disabled = false
      success_symbol = '[](bold fg:color_green)'
      error_symbol = '[](bold fg:color_red)'
      vimcmd_symbol = '[](bold fg:color_green)'
      vimcmd_replace_one_symbol = '[](bold fg:color_purple)'
      vimcmd_replace_symbol = '[](bold fg:color_purple)'
      vimcmd_visual_symbol = '[](bold fg:color_yellow)'
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      whitelist = { prefix = [ "$HOME/projects" "$HOME/nix" ]; };
      warn_timeout =
        "1m"; # Предупреждение, если загрузка занимает больше минуты
      # Расширенный лог для отладки
      stdlib = ''
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs
        log_status "Loading direnv configuration..."
      '';
    };
  };

  home.packages = with pkgs; [ carapace ];
}
