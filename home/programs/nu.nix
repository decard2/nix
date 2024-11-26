{pkgs, ...}: {
  programs.nushell = {
    enable = true;

    # Базовые настройки
    extraConfig = ''
      $env.EDITOR = 'zeditor'
      $env.VISUAL = 'zeditor'

      # Wayland specific
      $env.XDG_SESSION_TYPE = 'wayland'
      $env.XDG_CURRENT_DESKTOP = 'Hyprland'
      $env.XDG_SESSION_DESKTOP = 'Hyprland'

      # Настройки через config
      $env.config = {
        show_banner: false
      }

      # Подключаем bash-completion
      #source ${pkgs.bash-completion}/share/bash-completion/bash_completion

      # Системные комплиты
      # source ${pkgs.systemd}/share/bash-completion/completions/systemctl
      # source ${pkgs.systemd}/share/bash-completion/completions/journalctl
      # source ${pkgs.systemd}/share/bash-completion/completions/loginctl
      # source ${pkgs.docker}/share/bash-completion/completions/docker
      # source ${pkgs.kubectl}/share/bash-completion/completions/kubectl
    '';

    # Приветствие при запуске
    loginFile.text = ''
      echo "Здарова, хозяин! 🚀"
    '';

    # Алиасы для удобства
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      ".." = "cd ..";
      "..." = "cd ../..";
      c = "clear";

      rebuild = "sudo nixos-rebuild switch --flake .#emerald";
      update = "home-manager switch --flake .#decard";
      upgrade = "nix flake update";

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
    };
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      # character = {
      #   success_symbol = "[➜](bold green)";
      #   error_symbol = "[➜](bold red)";
      # };
      # Добавляем модули для системной инфы
      #memory_usage.disabled = false;
      #cpu_usage.disabled = false;
      #battery.disabled = false;
    };
  };

  #home.packages = with pkgs; [];
}
