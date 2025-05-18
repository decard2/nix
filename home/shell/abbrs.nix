{
  ### Базовые ###
  ll = "ls -l";
  la = "ls -lha";
  ".." = "cd ..";
  "..." = "cd ../..";
  b = "bash -l";

  ### NixOS ###
  nrb = "sudo nixos-rebuild switch";
  nup = "nix flake update --flake ~/nix";
  nd = "nvd diff /run/booted-system/ /run/current-system/";
  ns = "nix shell";
  nr = "nix run";

  ### Разработка ###
  g = "lazygit";
  dr = "deployRoodl";

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
  bc = "bun check";

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

  # Moon
  m = "moon";

  # Cargo
  c = "cargo";
  ca = "cargo add";
  crm = "cargo remove";
  cr = "cargo run";
  cw = "cargo watch -x \"run\"";
  cb = "cargo build";
  cbr = "cargo build --release";
  cc = "cargo check";
  cu = "cargo update";

  # Flox
  f = "flox";
  fin = "flox init";
  fu = "flox upgrade";
  fa = "flox activate";
  fi = "flox install";
  fs = "flox search";
  fsh = "flox show";

  ### DevOps ###
  # Helm
  h = "helm";
  hi = "helm install";
  hl = "helm list";
  hu = "helm upgrade";
  hun = "helm uninstall";

  # Kubectl
  k = "kubectl";
  kex = "kubectl exec -ti";
  kn = "kubectl get nodes";

  # Docker
  d = "docker";

  ds = "docker ps";
  di = "docker images";
  dex = "docker exec -it";
  dl = "docker logs";
  dlf = "docker logs -f";

  # Docker Compose
  dc = "docker compose";
  dcu = "docker compose up";
  dcd = "docker compose down";
  dcl = "docker compose logs";

  # Lazydocker
  lzd = "lazydocker";
}
