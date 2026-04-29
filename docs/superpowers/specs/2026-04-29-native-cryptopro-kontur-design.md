# Native CryptoPro / Контур stack on NixOS — design

**Date:** 2026-04-29
**Status:** approved (awaiting implementation plan)
**Scope:** Section B from brainstorm — native packaging of CryptoPro CSP, Cades
Browser Plug-in, Контур.Плагин, Контур.Диагностика as Nix derivations, with
Native Messaging integration into the existing Yandex.Browser. Replaces the
distrobox-based stack documented in [`docs/document-signing.md`](../../document-signing.md).

Out of scope (separate spec later): declarative browser policies, declarative
extension management, Yandex profile migration.

## Context

Current setup (commit `4496e1b`): document signing for Tochka and Diadoc using
the Aktiv Rutoken Lite USB token works through a **distrobox container**
(`tochka`, Ubuntu 22.04) that hosts CryptoPro CSP, Cades plugin, and Контур
plugins. The host runs Yandex.Browser natively (via
`miuirussia/yandex-browser.nix` flake) and talks to the container via three
**bridge scripts** (`~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge`) that
proxy stdio through `distrobox enter --no-tty tochka -- exec /opt/.../binary`.

The container approach works (real documents signed in Tochka and Diadoc), but
carries permanent overhead: distrobox + podman in the user environment, ~2 GB
container image, bridge scripts laden with workarounds (`unset LD_LIBRARY_PATH`,
explicit PATH injection, lazy `pcscd` start with `sudo -n`, `MODE=0666` on the
USB device because mapped-root in the container can't use `uaccess` ACLs, etc.).

Two research documents prepared the move off distrobox:
- [`docs/research/yandex-browser-nixos.md`](../../research/yandex-browser-nixos.md) — declarative browser config (NM-host paths empirically confirmed).
- [`docs/research/cryptopro-kontur-native-packaging.md`](../../research/cryptopro-kontur-native-packaging.md) — packaging strategy, references three working community examples (`sakost/nixos`, `SomeoneSerge/pkgs`, `danya02/cryptopro-nix`).

This spec acts on the second document.

## Decisions (from brainstorm)

| # | Decision | Choice |
|---|---|---|
| 1 | Scope | **B**: native packaging only; declarative browser later, separately |
| 2 | Code source | **A**: vendor-copy from `sakost/nixos` and `SomeoneSerge/pkgs`, adapt |
| 3 | License delivery | **B (hybrid)**: `requireFile` for CryptoPro CSP and Cades (login-walled), `fetchurl` for Контур stack (publicly downloadable) |
| 4 | distrobox fate | **A**: full removal — but only after native stack signs a real document |
| 5 | Repo layout | **B**: inline in module — single file `system/services/smartcard.nix` (rewrite of existing) holds 4 derivations + module config. No `pkgs/` directory created. |
| 6 | `kontur.updater` | **A**: don't package. Updates via `nix flake update` |
| 7 | NM hosts | **A**: system-wide via `environment.etc."chromium/native-messaging-hosts/<name>.json"` |

## Architecture

```
                          NixOS host (no container)
┌──────────────────────────────────────────────────────────────────┐
│  Yandex.Browser (miuirussia/yandex-browser.nix flake input)       │
│   • reads /etc/chromium/native-messaging-hosts/*.json             │
│      ↕ Chrome Native Messaging (stdio)                            │
│  /nix/store/...-cprocsp-cades/opt/cprocsp/bin/amd64/nmcades       │
│  /nix/store/...-kontur-plugin/opt/kontur.plugin/kontur.plugin.host│
│  /nix/store/...-diag-plugin/opt/diag.plugin/Diag.Plugin.nc        │
│      ↕ runtime API (CSP, certmgr, etc.)                           │
│  /opt/cprocsp → symlink in /nix/store (systemd-tmpfiles)          │
│      ↕ PCSC-Lite                                                  │
│  pcscd (services.pcscd.enable = true) + libccid (system plugin)   │
│      ↕ libusb via udev (MODE=0666 for ATTRS{idVendor}=="0a89")    │
│  Aktiv Rutoken Lite (USB)                                         │
└──────────────────────────────────────────────────────────────────┘
```

Key differences from the distrobox setup:

- No distrobox / Ubuntu / podman in this flow.
- No bridge scripts. Yandex.Browser invokes the binary directly out of `/nix/store`.
- `/opt/cprocsp` is a symlink in `/nix/store` (created at boot via
  `systemd.tmpfiles.rules`). Required because some binaries (notably
  `kontur.plugin.host`) hard-code paths under `/opt/cprocsp/...`.
- `pcscd` runs on the host. The previous conflict (host `pcscd` claiming the
  token and looping on `LIBUSB_ERROR_ACCESS`) was caused by the container
  layout; with distrobox gone, `pcscd` is the natural owner.

## File layout

```
nix/
├── flake.nix                                  ← unchanged
├── system/
│   └── services/
│       └── smartcard.nix                      ← REWRITE: 4 inline derivations
│                                                  + udev + pcscd
│                                                  + /opt symlinks
│                                                  + 3 NM host manifests
└── docs/
    ├── superpowers/specs/
    │   └── 2026-04-29-native-cryptopro-kontur-design.md   ← this file
    └── document-signing.md                    ← updated in step 6 of roadmap

REMOVED in step 6 of roadmap:
- distrobox + podman from home/dev/default.nix
- ~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge      (not in git)
- ~/.config/yandex-browser/NativeMessagingHosts/*.json   (not in git)
- container `tochka` and image `tochka-snapshot:working` (not in git)
```

`smartcard.nix` skeleton:

```nix
{ pkgs, lib, ... }:
let
  cryptoproCsp = pkgs.stdenv.mkDerivation {
    pname = "cprocsp";
    version = "5.0.13003-7";
    src = pkgs.requireFile {
      name = "linux-amd64_deb.tgz";
      hash = "sha256-...";
      message = ''Download from https://cryptopro.ru/products/csp/downloads ...'';
    };
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.pcsclite pkgs.gtk3 pkgs.cairo pkgs.glib ];
    # ... unpackPhase: dpkg-deb -x for needed .debs only
    # ... installPhase: copy to $out/opt/cprocsp
  };

  cprocspCades = pkgs.stdenv.mkDerivation { ... requireFile ... runtimeDependencies = [ cryptoproCsp ]; };
  konturPlugin = pkgs.stdenv.mkDerivation { ... fetchurl ... };
  diagPlugin   = pkgs.stdenv.mkDerivation { ... fetchurl ... };
in {
  environment.systemPackages = with pkgs; [
    cryptoproCsp cprocspCades konturPlugin diagPlugin
    pcsc-tools opensc
  ];

  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a89", MODE="0666"
  '';

  systemd.tmpfiles.rules = [
    "L+ /opt/cprocsp        - root root - ${cryptoproCsp}/opt/cprocsp"
    "d  /var/opt/cprocsp    0755 decard users -"
    "d  /etc/opt/cprocsp    0755 root   root  -"
  ];

  system.activationScripts.cprocspIntegrityDisable = lib.stringAfter [ "etc" ] ''
    # disable self-integrity check after autoPatchelfHook rewrites binaries
    ${cryptoproCsp}/opt/cprocsp/sbin/amd64/cpconfig -ini \
      '\config\parameters\protect_csp' -add string DisableIntegrity true || true
  '';

  environment.etc."chromium/native-messaging-hosts/ru.cryptopro.nmcades.json".text =
    builtins.toJSON {
      name = "ru.cryptopro.nmcades";
      description = "CryptoPro CAdES Browser plug-in";
      path = "${cprocspCades}/opt/cprocsp/bin/amd64/nmcades";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
        "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
      ];
    };

  environment.etc."chromium/native-messaging-hosts/kd.nc.json".text = builtins.toJSON { ... };
  environment.etc."chromium/native-messaging-hosts/kontur.plugin.json".text = builtins.toJSON { ... };
}
```

Approximate size: 250-300 lines. Acceptable for a single-purpose module.

## Components

### 1. `cryptoproCsp` — CryptoPro CSP 5.0.13003-7

- **src**: `requireFile` `linux-amd64_deb.tgz` (login required at cryptopro.ru).
- **debs to extract** (subset of the tarball — keep only what we use): `lsb-cprocsp-base`, `lsb-cprocsp-rdr-64`, `lsb-cprocsp-kc1-64`, `lsb-cprocsp-capilite-64`, `cprocsp-rdr-rutoken-64`, `cprocsp-rdr-pcsc-64`, `cprocsp-rdr-gui-gtk-64`, `lsb-cprocsp-pkcs11-64`, `lsb-cprocsp-ca-certs`. **Do NOT** install `ifd-rutokens` — `pkgs.ccid 1.7.1` already supports Rutoken Lite (verified during distrobox-era debugging).
- **autoPatchelfHook** rewrites `PT_INTERP` and `RPATH` of all CSP binaries.
- **`buildInputs`**: `pcsclite gtk3 cairo glib pango harfbuzz`.
- **Skip in installPhase**: do NOT symlink `lib/libssp.so` into `$out/lib` (collides with GCC's libssp).

### 2. `cprocspCades` — Cades Browser Plug-in 2.0.15600-1

- **src**: `requireFile` `cades-linux-amd64.tar.gz` (login required at cryptopro.ru).
- **debs to extract**: `cprocsp-pki-cades-64`, `cprocsp-pki-plugin-64`.
- **buildInputs**: `cryptoproCsp gtk3 glib cairo openssl`.
- **runtimeDependencies = [ cryptoproCsp ]` — autoPatchelfHook adds it to RPATH so `nmcades` finds CSP libs at runtime.
- Main artefact: `$out/opt/cprocsp/bin/amd64/nmcades`.

### 3. `konturPlugin` — Контур.Плагин 4.13.0.4561

- **src**: `fetchurl` from `https://api.kontur.ru/drive/v1/public/diag/files/kontur.plugin.002875.deb` (publicly downloadable).
- **buildInputs**: `cryptoproCsp gtk3 cairo glib openssl`.
- **Critical fix from research**: `kontur.plugin.host` does `open("/opt/cprocsp/sbin/amd64/cpconfig", ...)` — relies on the `/opt/cprocsp` tmpfiles symlink.
- **Critical fix from research**: `installPhase` must `rm -rf $out/opt/kontur.plugin/pkcs11` — that directory triggers a segfault inside the plugin.
- Main artefact: `$out/opt/kontur.plugin/kontur.plugin.host`.

### 4. `diagPlugin` — Контур.Диагностика 3.1.2.425

- **src**: `fetchurl` from `https://api.kontur.ru/drive/v1/public/diag/files/diag.plugin.002623.deb`.
- **buildInputs**: `cryptoproCsp gtk3 glib`.
- Straightforward — single binary `Diag.Plugin.nc`.

## Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| 1 | `kontur.plugin.host` hard-codes `/opt/cprocsp/...` paths | `systemd.tmpfiles.rules` symlinks `/opt/cprocsp` → `${cryptoproCsp}/opt/cprocsp` |
| 2 | CryptoPro self-integrity check fails after `autoPatchelfHook` rewrites binaries | activation script: `cpconfig -ini ... DisableIntegrity true` |
| 3 | `/opt/kontur.plugin/pkcs11/` causes Контур plugin segfault | `installPhase` of `konturPlugin`: `rm -rf $out/opt/kontur.plugin/pkcs11` |
| 4 | `libssp.so` from CryptoPro tarball collides with GCC's libssp if exported | do not symlink it into `$out/lib`; leave inside `$out/opt/cprocsp/lib/` |
| 5 | License file path `/etc/opt/cprocsp/license.ini` writable | tmpfiles creates `/etc/opt/cprocsp/` as dir; license-set runs in activation script |
| 6 | `/var/opt/cprocsp/users/<uid>/keys/` for uMy store | tmpfiles creates `/var/opt/cprocsp` writable for `decard:users` |
| 7 | Host pcscd previously failed with `LIBUSB_ERROR_ACCESS` | distrobox removed → no resource conflict; pcscd becomes natural owner |
| 8 | Контур download URL changes (CDN) | hard-coded URL → `nix flake update` re-checks; if dead, edit URL in derivation |
| 9 | Certificate not migrated automatically (it lives inside container's CSP store) | activation script (idempotent): for each `SCARD\rutoken_lt_*` container detected by `csptest -keyset -enum_cont -fqcn`, do `certmgr -inst -store uMy -cont '...'` |
| 10 | First boot after switch — token contention if old container still alive | step 3 of roadmap: stop and remove distrobox container BEFORE enabling host pcscd |

## Testing / Acceptance

After every roadmap step:

| Step | Acceptance gate |
|---|---|
| 1 | `nix build .#nixosConfigurations.emerald.config.system.build.toplevel` succeeds; each derivation present in `$out` after `dpkg-deb -x` |
| 2 | `ldd` of every binary shows no `not found`; resolved paths point to `/nix/store/...` |
| 3 | `pcsc_scan` lists "Aktiv Rutoken lite"; `csptest -keyset -enum_cont -fqcn` shows 3 containers; `certmgr -list -store uMy` shows 3 certs with `PrivateKey Link: Yes` |
| 4 | https://www.cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html reports «Плагин загружен», version 2.0.15600, lists 3 certs |
| 5 | Test document signed in Tochka. Test document signed in Diadoc (via Контур.Плагин). |
| 6 | `nix flake check` clean; `grep -r distrobox docs/research/` is the only remaining mention; container and bridge scripts gone |

## Roadmap

Six steps, each gated on its acceptance criterion. Estimated total: **6-7 hours**.

### Step 1 — skeleton derivations (~30 min)
Create `system/services/smartcard.nix` v2 (overwrite). Add 4 derivations with
just `requireFile`/`fetchurl` and a minimal `unpackPhase` doing `dpkg-deb -x`.
No `autoPatchelfHook` yet. `nix build` each one to confirm extraction.

### Step 2 — autoPatchelfHook (~2 h)
For each derivation in turn (CryptoPro → Cades → Diag → Kontur), add
`nativeBuildInputs = [ autoPatchelfHook ]` and the right `buildInputs`. Tune
`buildInputs` until `ldd $out/.../<binary>` shows zero unresolved entries. The
order matters: `cprocspCades`, `konturPlugin`, `diagPlugin` all transitively
need `cryptoproCsp`.

### Step 3 — runtime infrastructure (~2 h)
Add `services.pcscd`, `services.udev.extraRules`, `systemd.tmpfiles.rules`
(`/opt/cprocsp` symlink + `/var/opt/cprocsp` + `/etc/opt/cprocsp`),
activation script for `DisableIntegrity` and certificate import.

**Before this rebuild**: stop the distrobox container so it releases the
USB token (`distrobox stop tochka`).

### Step 4 — Native Messaging hosts (~30 min)
Three `environment.etc."chromium/native-messaging-hosts/..."` entries pointing
directly to nix-store binaries. Remove (manually, not in git) the old
user-level manifests in `~/.config/yandex-browser/NativeMessagingHosts/` so
they don't shadow the system ones with stale bridge paths.

### Step 5 — real signing (~30 min)
End-to-end smoke. Sign a tiny test PDF in Tochka. Sign a test document in
Diadoc. **If anything fails here, do NOT proceed to step 6** — the container
in `~/tmp/tochka-signing-backup/` is still the working baseline.

### Step 6 — distrobox cleanup (~30 min)
Single commit, only after step 5 passes:

- `distrobox stop tochka && distrobox rm tochka`
- `podman image rm tochka-snapshot:working` (the original Ubuntu image can stay or go)
- Remove `distrobox` and `podman` from `home/dev/default.nix`
- Delete `~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge` (not in git, but mention in commit)
- Rewrite `docs/document-signing.md` to describe the native-only path
- Final commit: «remove distrobox-based signing setup»

(User-level NM manifests in `~/.config/yandex-browser/NativeMessagingHosts/`
were removed in step 4. By step 6 nothing remains there.)

## Rollback

If the native stack proves unworkable after reasonable debugging:

1. `git revert` to the commit before this spec's implementation.
2. `nixos-rebuild switch` (restores distrobox/podman in user profile, restores
   old `smartcard.nix` with udev rule only).
3. `podman load -i ~/tmp/tochka-signing-backup/tochka-image.tar`
4. `distrobox-create --name tochka --image localhost/tochka-snapshot:working --yes`
5. Restore bridges and user-level NM manifests from
   `~/tmp/tochka-signing-backup/{bridges,nm-manifests}/`.

Time to recover: ~10 minutes. The backup snapshot exists and is documented.

## References

- [`docs/research/yandex-browser-nixos.md`](../../research/yandex-browser-nixos.md)
- [`docs/research/cryptopro-kontur-native-packaging.md`](../../research/cryptopro-kontur-native-packaging.md)
- [`docs/document-signing.md`](../../document-signing.md) (current distrobox setup, source of empirical risk list)
- [sakost/nixos: `modules/programs/cryptopro.nix`](https://github.com/sakost/nixos/blob/master/modules/programs/cryptopro.nix)
- [SomeoneSerge/pkgs: `pkgs/by-name/cp/cprocsp`](https://github.com/SomeoneSerge/pkgs/tree/master/pkgs/by-name/cp/cprocsp)
- [danya02/cryptopro-nix](https://github.com/danya02/cryptopro-nix)
