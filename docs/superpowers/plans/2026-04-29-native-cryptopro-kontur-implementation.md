# Native CryptoPro / Контур Stack — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the distrobox-based document-signing stack with native NixOS Nix derivations for CryptoPro CSP, Cades Browser Plug-in, Контур.Плагин, and Контур.Диагностика; wire them into the existing Yandex.Browser via system-level Native Messaging hosts; remove distrobox.

**Architecture:** Single-file NixOS module (`system/services/smartcard.nix`) holding 4 derivations (`stdenv.mkDerivation` with `dpkg-deb -x` + `autoPatchelfHook`), runtime infra (pcscd + udev + tmpfiles + activation script for `/opt/cprocsp` symlink and integrity-disable), and three `environment.etc."chromium/native-messaging-hosts/*.json"` entries pointing directly into `/nix/store`. Sources: `requireFile` for CryptoPro (login-walled), `fetchurl` for Контур (publicly downloadable). Vendored from `sakost/nixos` and `SomeoneSerge/pkgs` references with adaptation.

**Tech Stack:** Nix flakes, NixOS 25.x, `pkgs.stdenv.mkDerivation`, `pkgs.dpkg`, `pkgs.autoPatchelfHook`, `pkgs.requireFile`, `pkgs.fetchurl`, `services.pcscd`, `services.udev`, `systemd.tmpfiles`, `environment.etc`. NO test framework — verification is `nix build`, `ldd`, `pcsc_scan`, `csptest`, `certmgr`, and real-world signing.

**Spec:** [`docs/superpowers/specs/2026-04-29-native-cryptopro-kontur-design.md`](../specs/2026-04-29-native-cryptopro-kontur-design.md)

**Deviations from typical TDD:** NixOS modules do not have a unit-test surface in the conventional sense. Each task ends with a verification step (build success, command output, file existence) instead of a failing test. The "real test" lives in Phase 5 — signing actual documents.

---

## Pre-flight

**Working tree:** `/home/decard/nix`, branch `main`. The current module under change is `system/services/smartcard.nix`, which today contains only the udev rule. Spec has been committed (`c967cd0`). Backup of the working distrobox setup is in `~/tmp/tochka-signing-backup/` for rollback.

**Required local files:** `~/Downloads/linux-amd64_deb.tgz` (CryptoPro CSP) and `~/Downloads/cades-linux-amd64.tar.gz` (Cades plugin) must exist. Verify before starting:

```bash
ls -la ~/Downloads/linux-amd64_deb.tgz ~/Downloads/cades-linux-amd64.tar.gz
```

Both should be present (~38 MB and ~32 MB respectively). If missing — see spec for re-download instructions.

---

## File map

- **Modify:** `system/services/smartcard.nix` (currently 19 lines: udev rule only; will grow to ~250-300 lines)
- **Modify:** `home/dev/default.nix` (Phase 6: remove `distrobox` and `podman`)
- **Modify:** `docs/document-signing.md` (Phase 6: rewrite for native-only path)
- **Delete (not in git):**
  - `~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge`
  - `~/.config/yandex-browser/NativeMessagingHosts/{ru.cryptopro.nmcades,kd.nc,kontur.plugin}.json`
- **Delete (not in git, podman state):**
  - container `tochka`
  - image `tochka-snapshot:working`

---

## Phase 1 — Skeleton derivations (extraction only, no patchelf)

### Task 1: `cryptoproCsp` skeleton

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Get the CryptoPro tarball into `/nix/store` via `requireFile`, write a derivation that just unpacks the chosen `.deb`-s into `$out/opt/cprocsp/`. No patchelf yet.

- [ ] **Step 1: Add the tarball to /nix/store**

```bash
nix-store --add-fixed sha256 ~/Downloads/linux-amd64_deb.tgz
```

Expected output: `/nix/store/<hash>-linux-amd64_deb.tgz`. Save the SRI form for the derivation:

```bash
nix hash file ~/Downloads/linux-amd64_deb.tgz
```

Expected output: `sha256-<base64>=`. Copy this string — you'll paste it into the derivation in step 2.

- [ ] **Step 2: Replace contents of `system/services/smartcard.nix` with skeleton + first derivation**

```nix
{ pkgs, lib, ... }:
let
  cryptoproCsp = pkgs.stdenv.mkDerivation {
    pname = "cprocsp";
    version = "5.0.13003-7";

    src = pkgs.requireFile {
      name = "linux-amd64_deb.tgz";
      hash = "sha256-PASTE_FROM_STEP_1=";
      message = ''
        КриптоПро CSP требует ручной загрузки.

        1. Зайти на https://cryptopro.ru/products/csp/downloads
        2. Зарегистрироваться (бесплатно) и залогиниться
        3. Скачать "КриптоПро CSP для Linux (x64, deb)" — файл linux-amd64_deb.tgz
        4. nix-store --add-fixed sha256 linux-amd64_deb.tgz
        5. nix hash file linux-amd64_deb.tgz   # положить вывод в hash выше
      '';
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      runHook preUnpack
      tar xzf $src
      cd linux-amd64_deb
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p extracted
      for d in \
        lsb-cprocsp-base_*.deb \
        lsb-cprocsp-rdr-64_*.deb \
        lsb-cprocsp-kc1-64_*.deb \
        lsb-cprocsp-capilite-64_*.deb \
        cprocsp-rdr-rutoken-64_*.deb \
        cprocsp-rdr-pcsc-64_*.deb \
        cprocsp-rdr-gui-gtk-64_*.deb \
        lsb-cprocsp-pkcs11-64_*.deb \
        lsb-cprocsp-ca-certs_*.deb \
      ; do
        dpkg-deb -x $d extracted
      done
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt/cprocsp $out/
      cp -a extracted/etc        $out/
      cp -a extracted/var        $out/ 2>/dev/null || true
      runHook postInstall
    '';

    dontStrip = true;
    dontPatchELF = true;       # we patch in Phase 2
    dontAutoPatchelf = true;
  };
in {
  # Aktiv Co. — Rutoken family. MODE=0666 нужен потому что ранее требовался
  # mapped-root в distrobox; на нативном хосте `0664` + `uaccess` тоже бы
  # хватило, но 0666 универсально и не несёт риска (токен физически в твоей
  # машине). Оставляем как было.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a89", MODE="0666"
  '';

  environment.systemPackages = [
    cryptoproCsp
    pkgs.pcsc-tools
    pkgs.opensc
  ];
}
```

- [ ] **Step 3: Build only the derivation in isolation**

```bash
cd ~/nix
nix-build -E 'with import <nixpkgs> {}; (import ./system/services/smartcard.nix { inherit pkgs lib; }).config // builtins.head []' 2>&1 || true
# easier: build the full system but only the derivation
nix-build '<nixpkgs>' -A stdenv  # warm up
nix eval --raw .#nixosConfigurations.emerald.config.environment.systemPackages 2>&1 | head -3
```

Expected: no error during evaluation. If it complains about `requireFile` hash — the hash from step 1 was wrong; re-do step 1.

- [ ] **Step 4: Sanity-check the unpacked output**

```bash
nix build --no-link --print-out-paths .#nixosConfigurations.emerald.config.environment.systemPackages 2>/dev/null | head -1
# OR more directly:
nix-instantiate --eval -E '
  let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; };
  in (builtins.head m.environment.systemPackages).outPath
' 2>&1
```

Then build and inspect:
```bash
OUT=$(nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in builtins.head m.environment.systemPackages')
ls $OUT/opt/cprocsp/bin/amd64/ | head
```

Expected: list including `csptest`, `certmgr`, `cpconfig`, `nmcades` (wait — nmcades is in Cades, not CSP). For CSP expect `csptest`, `certmgr`, `cpconfig`, `cryptcp`. If empty — `unpackPhase`/`buildPhase` is wrong.

- [ ] **Step 5: Commit**

```bash
cd ~/nix
git add system/services/smartcard.nix
git commit -m "smartcard: scaffold cryptoproCsp derivation (no patchelf yet)"
```

---

### Task 2: `cprocspCades` skeleton

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Add second derivation in the `let` block, unpacking Cades plugin.

- [ ] **Step 1: Add Cades tarball to /nix/store and get hash**

```bash
nix-store --add-fixed sha256 ~/Downloads/cades-linux-amd64.tar.gz
nix hash file ~/Downloads/cades-linux-amd64.tar.gz
```

Save the SRI hash.

- [ ] **Step 2: Add `cprocspCades` to the `let` block, after `cryptoproCsp`**

Insert before the `in {`:

```nix
  cprocspCades = pkgs.stdenv.mkDerivation {
    pname = "cprocsp-cades";
    version = "2.0.15600-1";

    src = pkgs.requireFile {
      name = "cades-linux-amd64.tar.gz";
      hash = "sha256-PASTE_FROM_STEP_1=";
      message = ''
        КриптоПро ЭЦП Browser plug-in — ручная загрузка.

        1. https://cryptopro.ru/products/cades/plugin (нужна регистрация на cryptopro.ru)
        2. Скачать "Linux (deb)" — файл cades-linux-amd64.tar.gz
        3. nix-store --add-fixed sha256 cades-linux-amd64.tar.gz
        4. nix hash file cades-linux-amd64.tar.gz
      '';
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      runHook preUnpack
      tar xzf $src
      cd cades-linux-amd64
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p extracted
      for d in cprocsp-pki-cades-64_*.deb cprocsp-pki-plugin-64_*.deb; do
        dpkg-deb -x $d extracted
      done
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt/cprocsp $out/
      runHook postInstall
    '';

    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;
  };
```

Also add `cprocspCades` to `environment.systemPackages`.

- [ ] **Step 3: Build and verify nmcades is present**

```bash
cd ~/nix
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 1)'
```

(`elemAt 1` because cprocspCades is second after cryptoproCsp).

Then:
```bash
OUT=$(readlink -f result); ls $OUT/opt/cprocsp/bin/amd64/nmcades
```

Expected: file exists. `file $OUT/opt/cprocsp/bin/amd64/nmcades` should report `ELF 64-bit LSB executable`.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: scaffold cprocspCades derivation"
```

---

### Task 3: `konturPlugin` skeleton (fetchurl)

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Add Контур.Плагин derivation. Source via `fetchurl` (public CDN). Includes the segfault-fix from spec — remove `/opt/kontur.plugin/pkcs11/`.

- [ ] **Step 1: Compute hash for the .deb**

```bash
nix-prefetch-url --type sha256 --print-path \
  https://api.kontur.ru/drive/v1/public/diag/files/kontur.plugin.002875.deb
```

Or with SRI:
```bash
nix store prefetch-file https://api.kontur.ru/drive/v1/public/diag/files/kontur.plugin.002875.deb
```

Save the SRI hash.

> If the URL returns 404 (Контур rotates versions), grab the current one by following the redirect from `https://install.kontur.ru/files/kontur.plugin_amd64.deb`:
> ```bash
> curl -sIL https://install.kontur.ru/files/kontur.plugin_amd64.deb | grep -i location
> ```
> and use the new URL.

- [ ] **Step 2: Add `konturPlugin` to the `let` block**

```nix
  konturPlugin = pkgs.stdenv.mkDerivation {
    pname = "kontur-plugin";
    version = "4.13.0.4561";

    src = pkgs.fetchurl {
      url = "https://api.kontur.ru/drive/v1/public/diag/files/kontur.plugin.002875.deb";
      hash = "sha256-PASTE_FROM_STEP_1=";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      runHook preUnpack
      mkdir extracted
      dpkg-deb -x $src extracted
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt/kontur.plugin $out/
      # CRITICAL (research/cryptopro-kontur-native-packaging.md):
      # /opt/kontur.plugin/pkcs11/ triggers a segfault inside the host plugin.
      rm -rf $out/opt/kontur.plugin/pkcs11
      runHook postInstall
    '';

    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;
  };
```

Add `konturPlugin` to `environment.systemPackages`.

- [ ] **Step 3: Build and verify**

```bash
cd ~/nix
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 2)'
OUT=$(readlink -f result); ls $OUT/opt/kontur.plugin/
```

Expected: directory contents (binaries, configs), but NO `pkcs11/` subdir (we deleted it). Verify:

```bash
ls $OUT/opt/kontur.plugin/pkcs11 2>&1
# Expected: cannot access ... No such file or directory
```

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: scaffold konturPlugin derivation (segfault-fix included)"
```

---

### Task 4: `diagPlugin` skeleton (fetchurl)

**Files:**
- Modify: `system/services/smartcard.nix`

- [ ] **Step 1: Compute hash for diag.plugin .deb**

```bash
nix store prefetch-file https://api.kontur.ru/drive/v1/public/diag/files/diag.plugin.002623.deb
```

- [ ] **Step 2: Add `diagPlugin` to `let` block**

```nix
  diagPlugin = pkgs.stdenv.mkDerivation {
    pname = "diag-plugin";
    version = "3.1.2.425";

    src = pkgs.fetchurl {
      url = "https://api.kontur.ru/drive/v1/public/diag/files/diag.plugin.002623.deb";
      hash = "sha256-PASTE_FROM_STEP_1=";
    };

    nativeBuildInputs = [ pkgs.dpkg ];

    unpackPhase = ''
      runHook preUnpack
      mkdir extracted
      dpkg-deb -x $src extracted
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a extracted/opt/diag.plugin $out/
      runHook postInstall
    '';

    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;
  };
```

Add `diagPlugin` to `environment.systemPackages`.

- [ ] **Step 3: Build and verify**

```bash
cd ~/nix
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 3)'
OUT=$(readlink -f result); ls $OUT/opt/diag.plugin/Diag.Plugin.nc
```

Expected: file exists.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: scaffold diagPlugin derivation"
```

---

## Phase 2 — autoPatchelfHook for each derivation

### Task 5: Patch `cryptoproCsp`

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Make `nmcades`, `csptest`, `certmgr`, etc. find their shared libraries through `RPATH` instead of `/lib/x86_64-linux-gnu`.

- [ ] **Step 1: Add autoPatchelfHook + buildInputs to `cryptoproCsp`**

Inside the `cryptoproCsp` derivation, replace:

```nix
    nativeBuildInputs = [ pkgs.dpkg ];
```

with:

```nix
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      pcsclite
      gtk3
      cairo
      glib
      pango
      harfbuzz
      atk
      gdk-pixbuf
      stdenv.cc.cc.lib
    ];
```

And remove these three lines (they prevented patchelf):

```nix
    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;
```

But keep `dontStrip = true;` — CryptoPro binaries should not be stripped (license/integrity).

So final tail of the derivation:
```nix
    dontStrip = true;
  };
```

- [ ] **Step 2: Build**

```bash
cd ~/nix
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.head m.environment.systemPackages)'
```

Expected: build succeeds. autoPatchelfHook will print which interpreters/RPATHs it patched.

If it fails with "missing library X" — add the corresponding nixpkg to `buildInputs`. Common candidates:
- `nss`, `nspr` — for crypto libs
- `libxml2`, `libxslt`
- `expat`
- `dbus`

- [ ] **Step 3: Verify ldd is clean for nmcades and friends**

```bash
OUT=$(readlink -f result)
ldd $OUT/opt/cprocsp/bin/amd64/csptest 2>&1 | grep -E "not found|=>"  | head -20
```

Expected: every `=>` resolves to `/nix/store/...`. **No `not found` lines.** If any — find the missing lib via `nix-locate <libname>` and add to `buildInputs`.

Then check the most important ones:
```bash
for b in csptest certmgr cpconfig; do
  echo "=== $b ==="
  ldd $OUT/opt/cprocsp/bin/amd64/$b 2>&1 | grep "not found" || echo "OK"
done
```

Expected: all `OK`.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: autoPatchelfHook for cryptoproCsp"
```

---

### Task 6: Patch `cprocspCades`

**Files:**
- Modify: `system/services/smartcard.nix`

- [ ] **Step 1: Add autoPatchelfHook + buildInputs (transitively cryptoproCsp)**

In the `cprocspCades` derivation, change `nativeBuildInputs` and add `buildInputs` and `runtimeDependencies`:

```nix
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      glib
      cairo
      openssl
      stdenv.cc.cc.lib
    ];

    # nmcades dlopen()-ит libcppki.so.4 и т.д. из cryptoproCsp в рантайме.
    # autoPatchelfHook добавит cryptoproCsp в RPATH каждого ELF.
    runtimeDependencies = [ cryptoproCsp ];
```

Remove `dontStrip = true; dontPatchELF = true; dontAutoPatchelf = true;` and replace with just `dontStrip = true;`.

- [ ] **Step 2: Build**

```bash
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 1)'
```

Expected: success. If "missing libcppcades.so" or similar — `cryptoproCsp` derivation didn't ship it, or autoPatchelf didn't pick up `runtimeDependencies` — try adding `cryptoproCsp.outPath + "/opt/cprocsp/lib/amd64"` via `appendRunpaths` (escape hatch).

- [ ] **Step 3: Verify nmcades has clean ldd**

```bash
OUT=$(readlink -f result)
ldd $OUT/opt/cprocsp/bin/amd64/nmcades 2>&1 | grep "not found" || echo "OK"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: autoPatchelfHook for cprocspCades"
```

---

### Task 7: Patch `diagPlugin`

**Files:**
- Modify: `system/services/smartcard.nix`

- [ ] **Step 1: Add autoPatchelfHook + buildInputs**

```nix
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      glib
      cairo
      stdenv.cc.cc.lib
    ];

    runtimeDependencies = [ cryptoproCsp ];
```

Remove `dontPatchELF` and `dontAutoPatchelf`.

- [ ] **Step 2: Build and verify**

```bash
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 3)'
OUT=$(readlink -f result)
ldd $OUT/opt/diag.plugin/Diag.Plugin.nc 2>&1 | grep "not found" || echo "OK"
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: autoPatchelfHook for diagPlugin"
```

---

### Task 8: Patch `konturPlugin`

**Files:**
- Modify: `system/services/smartcard.nix`

- [ ] **Step 1: Add autoPatchelfHook + buildInputs**

```nix
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      cryptoproCsp
      gtk3
      cairo
      glib
      openssl
      stdenv.cc.cc.lib
    ];

    runtimeDependencies = [ cryptoproCsp ];
```

Remove `dontPatchELF` and `dontAutoPatchelf`.

- [ ] **Step 2: Build and verify**

```bash
nix-build -E 'let pkgs = import <nixpkgs> {}; m = import ./system/services/smartcard.nix { inherit pkgs; lib = pkgs.lib; }; in (builtins.elemAt m.environment.systemPackages 2)'
OUT=$(readlink -f result)
ldd $OUT/opt/kontur.plugin/kontur.plugin.host 2>&1 | grep "not found" || echo "OK"
```

Expected: `OK`. If `not found: libcpsspade.so.4` — that's a CSP lib, ensure `runtimeDependencies = [ cryptoproCsp ]` is present.

- [ ] **Step 3: Build the WHOLE NixOS configuration to confirm no eval/build errors**

```bash
cd ~/nix
sudo nixos-rebuild build --flake .#emerald
```

Expected: build succeeds, ends with `building '...-nixos-system-emerald-...drv'`. **Do NOT switch yet** — Phase 3 hasn't enabled pcscd / tmpfiles, the system isn't usable for signing.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: autoPatchelfHook for konturPlugin"
```

---

## Phase 3 — Runtime infrastructure

### Task 9: Stop distrobox container, enable host pcscd

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Let host pcscd take over the token.

- [ ] **Step 1: Stop and remove the running distrobox container**

```bash
distrobox stop tochka 2>&1 || true
sleep 2
podman ps -a --filter name=tochka
# expected: tochka shown as Exited or absent
```

Container is stopped but image remains (will be deleted in Phase 6).

> Why now: host pcscd can only access the USB token if no other process holds it. The container's pcscd was the previous holder.

- [ ] **Step 2: Add `services.pcscd` to the module**

In `system/services/smartcard.nix`, inside the module block (after `services.udev.extraRules`):

```nix
  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid ];
```

- [ ] **Step 3: Rebuild and switch**

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#emerald
```

Expected: success. `pcscd` should be active afterwards.

- [ ] **Step 4: Verify token is visible to host pcscd**

```bash
systemctl status pcscd --no-pager | head -5
# expected: Active: active (running)

pcsc_scan -n
# expected: "0: Aktiv Rutoken lite 00 00" with ATR=Rutokenlite
# Press Ctrl-C after verifying
```

If pcscd shows `LIBUSB_ERROR_ACCESS` in `journalctl -u pcscd -n 30 --no-pager` — verify token and udev rule:
```bash
ls -la /dev/bus/usb/001/$(printf "%03d" $(cat /sys/bus/usb/devices/1-3.1/devnum))
# expected: crw-rw-rw- (mode 666)
```

- [ ] **Step 5: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: enable host pcscd with ccid plugin"
```

---

### Task 10: tmpfiles — `/opt/cprocsp` symlink + writable state dirs

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Hard-coded paths in CryptoPro and Контур binaries must resolve. `/opt/cprocsp` becomes a symlink to the nix-store CSP install. `/var/opt/cprocsp` is writable for the user (user keys live here). `/etc/opt/cprocsp` is writable for license + ini.

- [ ] **Step 1: Add `systemd.tmpfiles.rules`**

After the `services.pcscd` block in the module:

```nix
  systemd.tmpfiles.rules = [
    # /opt/cprocsp is a symlink into the nix-store install.
    # Required because kontur.plugin.host hard-codes "/opt/cprocsp/sbin/amd64/cpconfig"
    # and CryptoPro tools also use /opt/cprocsp internally.
    "L+ /opt/cprocsp 0755 root root - ${cryptoproCsp}/opt/cprocsp"

    # /var/opt/cprocsp/users/<uid>/keys/  ← uMy store (per-user)
    "d  /var/opt/cprocsp                   0755 root   root  -"
    "d  /var/opt/cprocsp/users             0755 root   root  -"
    "d  /var/opt/cprocsp/users/1000        0700 decard users -"
    "d  /var/opt/cprocsp/users/1000/keys   0700 decard users -"

    # /etc/opt/cprocsp ← license.ini, config files
    "d  /etc/opt/cprocsp                   0755 root   root  -"
  ];
```

> Note: UID `1000` is hard-coded for `decard`. If user has a different UID, adapt or use `lib.mkIf`.

- [ ] **Step 2: Rebuild and verify**

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#emerald
ls -la /opt/cprocsp
# expected: lrwxrwxrwx ... /opt/cprocsp -> /nix/store/...-cprocsp-5.0.13003-7/opt/cprocsp
ls -la /opt/cprocsp/sbin/amd64/cpconfig
# expected: file exists, executable
```

- [ ] **Step 3: Try running cpconfig directly from the nix-store path**

```bash
/opt/cprocsp/sbin/amd64/cpconfig -ini '\config\version' -view 2>&1 | head -5
```

Expected: prints version info (no segfault, no "library not found").

If it fails with a self-integrity error like "Integrity check failed" — that's expected and will be solved in Task 11.

- [ ] **Step 4: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: tmpfiles for /opt/cprocsp symlink and state dirs"
```

---

### Task 11: Activation script — DisableIntegrity + certificate import

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Run two one-shot setup commands at activation:
1. `cpconfig DisableIntegrity true` — bypass self-integrity (binaries were patchelf'd, hashes don't match upstream).
2. `certmgr -inst -store uMy -cont 'SCARD\rutoken_lt_*'` — import certs from token into the user CSP store. Idempotent — re-running doesn't break.

- [ ] **Step 1: Add `system.activationScripts`**

After `systemd.tmpfiles.rules` in the module:

```nix
  system.activationScripts.cprocspSetup = lib.stringAfter [ "etc" "var" ] ''
    set +e
    # 1. Disable self-integrity check. autoPatchelfHook rewrote PT_INTERP and RPATH
    #    in every CSP binary, so the integrity hashes don't match. Without this,
    #    cpconfig and other tools fail at startup with "Integrity check failed".
    /opt/cprocsp/sbin/amd64/cpconfig -ini \
      '\config\parameters\protect_csp' -add string DisableIntegrity true \
      >/dev/null 2>&1 || true
  '';
```

> Note: certificate import is intentionally **not** automated in this script. The token must be inserted, the user must run a one-time command after first deploy. We document it in `docs/document-signing.md` (updated in Phase 6). This is more reliable than an idempotent activation script that could fail silently when the token is absent.

- [ ] **Step 2: Rebuild + run cpconfig directly to confirm DisableIntegrity took**

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#emerald

# Verify the setting was applied
sudo /opt/cprocsp/sbin/amd64/cpconfig -ini '\config\parameters\protect_csp' -view 2>&1 | grep -i integrity
# Expected: DisableIntegrity = true (or similar)
```

- [ ] **Step 3: Run csptest manually to verify CSP works against the token**

```bash
/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -fqcn -verifycontext 2>&1 | tail -10
```

Expected:
```
\\.\Aktiv Rutoken lite 00 00\73510298@2023-05-24-Shachnev Viktor Aleksandrovich
\\.\Aktiv Rutoken lite 00 00\86392425@2024-08-13-Shachnev Viktor Aleksandrovich
\\.\Aktiv Rutoken lite 00 00\98643878@2025-10-13-Shachnev Viktor Aleksandrovich
OK.
```

If empty list — token may not be readable; check `lsusb`, udev rule, pcscd journal.

- [ ] **Step 4: Manually import the most recent cert into uMy**

```bash
# Pick the most recent container (largest year-month-day prefix):
NEWEST=$(/opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -fqcn -verifycontext 2>/dev/null \
  | grep '@' | sort -t@ -k2,2r | head -1 | sed 's/^[[:space:]]*//')

echo "Importing: $NEWEST"
/opt/cprocsp/bin/amd64/certmgr -inst -store uMy -cont "$NEWEST" 2>&1 | tail -10
# Expected: "Installation complete." or similar; PrivateKey Link: Yes

# Verify it's listed:
/opt/cprocsp/bin/amd64/certmgr -list -store uMy 2>&1 | grep "Subject\|PrivateKey Link" | head -10
```

Expected: subject contains "Шачнев Виктор Александрович" with `PrivateKey Link: Yes`.

- [ ] **Step 5: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: activation script for DisableIntegrity"
```

---

## Phase 4 — Native Messaging hosts

### Task 12: Three system-level NM manifests + remove user-level shadows

**Files:**
- Modify: `system/services/smartcard.nix`

**Goal:** Browser invokes the binary directly out of `/nix/store` — no bridges.

- [ ] **Step 1: Compute extension allowed_origins lists by reading the deb-shipped reference manifests**

```bash
cat /opt/cprocsp/bin/amd64/nmcades 2>/dev/null  # just confirm path
# better — read the original manifest the deb ships:
ls /nix/store/*-cprocsp-cades*/etc/opt/chrome/native-messaging-hosts/ 2>&1 | head
```

Get the original `allowed_origins` lists. We'll keep them verbatim so any current/future Контур or CryptoPro extension ID is accepted.

For reference, our current ones (in `~/.config/yandex-browser/NativeMessagingHosts/`):

```
ru.cryptopro.nmcades:
  - chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/
  - chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/

kd.nc: 7 IDs (see existing kd.nc.json)

kontur.plugin: 6 IDs (see existing kontur.plugin.json)
```

- [ ] **Step 2: Add three `environment.etc` entries**

After the activation script in the module:

```nix
  environment.etc = {
    "chromium/native-messaging-hosts/ru.cryptopro.nmcades.json".text =
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

    "chromium/native-messaging-hosts/kd.nc.json".text =
      builtins.toJSON {
        name = "kd.nc";
        description = "Diag.Plugin Native Messaging Host";
        path = "${diagPlugin}/opt/diag.plugin/Diag.Plugin.nc";
        type = "stdio";
        allowed_origins = [
          "chrome-extension://inlmamahcfioibldbpbaechbpeeaelin/"
          "chrome-extension://pioommjcfaefbcpbdokfoadjhlmahjjm/"
          "chrome-extension://adipnhhjfmoehhkepljbifddkobenooa/"
          "chrome-extension://fmdmnjcgegbabdefddkijefeadkhchcn/"
          "chrome-extension://momffihklfhkoakghidmkdocdkbfmoac/"
          "chrome-extension://kbeplgmhdbgnbpfkcmndbhjfadkhinhn/"
          "chrome-extension://nhbmmgegnhdhkcclaandbaipceebnckc/"
        ];
      };

    "chromium/native-messaging-hosts/kontur.plugin.json".text =
      builtins.toJSON {
        name = "kontur.plugin";
        description = "Kontur.Plugin";
        path = "${konturPlugin}/opt/kontur.plugin/kontur.plugin.host";
        type = "stdio";
        allowed_origins = [
          "chrome-extension://hnhppcgejeffnbnioloohhmndpmclaga/"
          "chrome-extension://nejicfcnfnecdilmajlppdcgbjilgeec/"
          "chrome-extension://akpjpngckapnibajopggmfhnchfpnkkf/"
          "chrome-extension://momffihklfhkoakghidmkdocdkbfmoac/"
          "chrome-extension://kbeplgmhdbgnbpfkcmndbhjfadkhinhn/"
          "chrome-extension://nhbmmgegnhdhkcclaandbaipceebnckc/"
        ];
      };
  };
```

- [ ] **Step 3: Rebuild**

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#emerald
ls /etc/chromium/native-messaging-hosts/
# expected: kd.nc.json, kontur.plugin.json, ru.cryptopro.nmcades.json
cat /etc/chromium/native-messaging-hosts/ru.cryptopro.nmcades.json | head -5
# expected: path = "/nix/store/...nmcades"
```

- [ ] **Step 4: Remove user-level NM manifests so they don't shadow system ones**

```bash
rm -v ~/.config/yandex-browser/NativeMessagingHosts/{ru.cryptopro.nmcades,kd.nc,kontur.plugin}.json
ls -la ~/.config/yandex-browser/NativeMessagingHosts/
# expected: directory empty (or has only files we didn't put there)
```

- [ ] **Step 5: Restart Yandex.Browser fully**

```bash
pkill -f yandex_browser 2>&1 || true
sleep 2
# Then user manually launches Yandex.Browser from Hyprland menu / app launcher.
```

- [ ] **Step 6: Verify in browser**

Open: https://www.cryptopro.ru/sites/default/files/products/cades/demopage/cades_bes_sample.html

Expected on the page:
- "Расширение загружено"
- "Плагин загружен"
- "Криптопровайдер загружен"
- "Версия плагина: 2.0.15600"
- "Версия криптопровайдера: 5.0.13003"
- "Сертификаты My: 3"

If "Ожидание загрузки провайдера" or empty cert list — check:
```bash
journalctl --user -n 50 --no-pager  # any errors from yandex-browser?
ls /etc/chromium/native-messaging-hosts/   # all three present?
ls -la ~/.config/yandex-browser/NativeMessagingHosts/   # empty?
```

- [ ] **Step 7: Commit**

```bash
git add system/services/smartcard.nix
git commit -m "smartcard: native-messaging hosts pointing into /nix/store"
```

---

## Phase 5 — Real-world acceptance

### Task 13: Sign actual documents in Tochka and Diadoc

**Files:** none (manual user action)

**Goal:** Confirm the native stack signs documents successfully in both target services. **This is the gate before Phase 6 cleanup.**

- [ ] **Step 1: Open Точка business banking, sign a test document**

User action. Use a low-stakes document (test transfer, account statement signature, etc.). Confirm:
- The certificate selector shows the same 3 certs as the proof page.
- Signing UI prompts for PIN once.
- Document submits successfully.

- [ ] **Step 2: Open Контур.Диадок, sign a test document**

User action. Select an existing draft / test invoice. Confirm:
- Контур.Плагин loads (no "Установите плагин" banner).
- Cert selector lists the active 2025-10-13 cert.
- PIN prompt appears.
- Document signs without errors.

- [ ] **Step 3: If both pass — commit a marker**

```bash
cd ~/nix
git commit --allow-empty -m "smartcard: native stack proven — signed docs in Tochka and Diadoc"
```

> If either fails: STOP. Native stack isn't ready. Debug from logs:
> ```bash
> journalctl -u pcscd -n 100 --no-pager
> ls /etc/chromium/native-messaging-hosts/  # all three present?
> /opt/cprocsp/bin/amd64/csptest -keyset -enum_cont -fqcn -verifycontext
> ```
> Don't proceed to Phase 6. The distrobox snapshot in `~/tmp/tochka-signing-backup/` is your fallback.

---

## Phase 6 — Cleanup (only after Phase 5 passes)

### Task 14: Remove distrobox + podman from user packages, delete bridge scripts

**Files:**
- Modify: `home/dev/default.nix`

- [ ] **Step 1: Edit `home/dev/default.nix`**

Remove `distrobox` and `podman` from `home.packages`. Diff:

```nix
   home.packages = with pkgs; [
     inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.flox
     gh
     uv
-    distrobox
-    podman
   ];
```

- [ ] **Step 2: Rebuild**

```bash
cd ~/nix
sudo nixos-rebuild switch --flake .#emerald
which distrobox podman 2>&1
# expected: not found / no path output
```

- [ ] **Step 3: Delete bridge scripts (not in git)**

```bash
rm -v ~/.local/bin/{nmcades,kd-nc,kontur-plugin}-bridge
ls ~/.local/bin/ | grep -iE "nmcades|kd-nc|kontur" || echo "all gone"
```

- [ ] **Step 4: Commit**

```bash
git add home/dev/default.nix
git commit -m "home/dev: remove distrobox and podman; native signing stack online"
```

---

### Task 15: Delete container `tochka` and image

**Files:** none (podman state)

> If Task 14's `nixos-rebuild switch` already removed podman, this whole task is a no-op (the data is gone from user's reach). If podman is still installed because it's used elsewhere — then run these. Check `which podman` first.

- [ ] **Step 1: Check whether podman still exists somewhere**

```bash
which podman
# If "not found" — skip the rest of this task entirely.
```

- [ ] **Step 2 (only if podman exists): Stop and remove container**

```bash
distrobox stop tochka 2>&1 || true
distrobox rm tochka 2>&1 || true
podman rm -f tochka 2>&1 || true
podman image rm -f tochka-snapshot:working 2>&1 || true
podman ps -a 2>&1 | grep tochka || echo "container gone"
```

- [ ] **Step 3 (no commit needed — this is podman state, not git)**

---

### Task 16: Rewrite `docs/document-signing.md` for the native path

**Files:**
- Modify: `docs/document-signing.md`

**Goal:** The doc currently describes the distrobox setup. Replace with native-only.

- [ ] **Step 1: Read current `docs/document-signing.md`**

```bash
cat ~/nix/docs/document-signing.md | head -40
```

- [ ] **Step 2: Replace the doc body**

The new content should cover:

- Architecture diagram (host-only, no container)
- Prerequisites (which deb files to download from cryptopro.ru, where to put them)
- Initial setup steps (`nix-store --add-fixed sha256` for the two manual archives, then `nixos-rebuild switch`)
- One-time post-install: install certificate from token (`certmgr -inst -store uMy -cont '...'`)
- Verification steps
- Maintenance: how to update CryptoPro / Cades / Контур versions (re-add to /nix/store + update hash, or `nix flake update` for fetchurl-sourced ones)
- Troubleshooting: what to check when signing breaks (pcscd journal, ldd output, `/opt/cprocsp` symlink)
- Legacy section: link to `~/tmp/tochka-signing-backup/README.md` for the now-deprecated distrobox approach (still useful for emergency rollback)

Specifically, replace lines 1-N (the "Архитектура" section onward) with the new architecture section from this plan's Phase 1 spec, and adjust the rest accordingly.

The file should reference the new module path: `system/services/smartcard.nix`.

- [ ] **Step 3: Sanity check the new doc**

```bash
grep -i distrobox ~/nix/docs/document-signing.md
# expected: zero or only one mention in the "rollback / legacy" section
```

- [ ] **Step 4: Commit**

```bash
cd ~/nix
git add docs/document-signing.md
git commit -m "docs: document-signing.md rewritten for native NixOS path"
```

---

## Self-review (filled in by writer)

**Spec coverage:**
- §Architecture → Phase 1-3 (file structure, derivations, runtime infra)
- §Components × 4 → Tasks 1-8
- §Risks #1 (kontur hardcode `/opt/cprocsp`) → Task 10 (tmpfiles symlink)
- §Risks #2 (integrity check after patchelf) → Task 11 (DisableIntegrity)
- §Risks #3 (kontur pkcs11 segfault) → Task 3 step 2 (`rm -rf` in installPhase)
- §Risks #4 (libssp collision) → not symlinked: avoided by leaving `$out/lib` empty (we cp `/opt/cprocsp` only); confirmed implicitly by Task 5
- §Risks #5,6 (license/state writable paths) → Task 10 tmpfiles
- §Risks #7 (pcscd takeover) → Task 9
- §Risks #8 (Контур URL drifts) → Task 3 step 1 fallback procedure
- §Risks #9 (cert import) → Task 11 step 4 (manual import, documented in Phase 6)
- §Risks #10 (token contention during transition) → Task 9 step 1 (stop container before pcscd activation)
- §Roadmap step 1-6 → Phases 1-6 of plan ✓
- §Testing acceptance gates → matched task-by-task

**Type/name consistency:** all 4 derivation names are `cryptoproCsp`, `cprocspCades`, `konturPlugin`, `diagPlugin` — used consistently across tasks. NM manifest names match the file names exactly.

**Placeholders:** the `sha256-PASTE_FROM_STEP_1=` placeholders are explicit user-fill-in points with the command shown in step 1 of each task — these are intentional (hash values cannot be predicted at plan-write time).
