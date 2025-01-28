{
  ### Базовые ###
  ll = "ls -l";
  la = "ls -la";
  ".." = "cd ..";
  "..." = "cd ../..";
  c = "clear";
  b = "^/run/current-system/sw/bin/bash -l";

  ### NixOS ###
  nrb = "sudo nixos-rebuild switch --flake .#emerald";
  nup = "nix flake update";
  nd = "nvd diff /run/booted-system/ /run/current-system/";

  ### Разработка ###
  g = "gitui";
  dr = "deployRoodl";
  ## Flox
  fa = "flox activate -- nu";
  ## Bun
  ba = "bun add";
  bad = "bun add --dev";
  brm = "bun remove";
  bin = "bun install";
  br = "bun run";
  bx = "bun x";
  bu = "bun update";
  bout = "bun outdated";
  bd = "bun dev";
  bs = "bun start";
  bb = "bun run build";
  # PNPM
  pn = "pnpm";
  pin = "pnpm install";
  pa = "pnpm add";
  pad = "pnpm add --save-dev";
  prm = "pnpm remove";
  px = "pnpm dlx";
  ps = "pnpm start";
  pr = "pnpm run";
  pb = "pnpm build";
  pd = "pnpm dev";
  pout = "pnpm outdated";
  pu = "pnpm update";

  ### DevOps ###
  # Helm
  h = "helm";
  hi = "helm install";
  hl = "helm list";
  hu = "helm upgrade";
  # Kubectl
  k = "kubectl";
  kaf = "kubectl apply -f";
  kex = "kubectl exec -ti";
  kg = "kubectl get";
  kgp = "kubectl get pods";
  kgn = "kubectl get nodes";
  kd = "kubectl describe";
  kdp = "kubectl describe pod";
  kdn = "kubectl describe node";
  kl = "kubectl logs";
  klf = "kubectl logs -f";
  kcp = "kubectl cp";
  kdl = "kubectl delete";
  kdlp = "kubectl delete pod";
  # Docker
  d = "docker";
  dc = "docker-compose";
  ds = "docker ps";
  di = "docker images";
  dex = "docker exec -it";
  dl = "docker logs";
  dlf = "docker logs -f";

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
}
