# Remnawave Sync Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace 6 bash systemd sync services with one Python script that does full reconcile with dry-run/apply and auto DB backup.

**Architecture:** Single `sync.py` file with `requests` library. Data-driven entity definitions with shared reconcile logic. Packaged via `pkgs.writers.writePython3Bin`, runs as one systemd oneshot service.

**Tech Stack:** Python 3, requests, argparse, NixOS systemd

---

## Context

### API Details

- Base URL: `https://rolder.net/api`
- Auth: `Authorization: Bearer <token>` (token from env `REMNAWAVE_API_TOKEN`)
- Health check: `GET /api/system/health` (no auth)
- All responses wrapped in `{"response": ...}`

### API Endpoints

| Entity | GET (list) | POST (create) | PATCH (update) | DELETE |
|--------|-----------|---------------|----------------|--------|
| config-profiles | — | — | `PATCH /api/config-profiles` body: `{uuid, config}` | — |
| internal-squads | `GET /api/internal-squads` → `.response.internalSquads[]` | — | `PATCH /api/internal-squads` body: `{uuid, inbounds}` | — |
| nodes | `GET /api/nodes` → `.response[]` | `POST /api/nodes` | `PATCH /api/nodes` (requires `uuid`) | `DELETE /api/nodes/{uuid}` |
| hosts | `GET /api/hosts` → `.response[]` | `POST /api/hosts` | `PATCH /api/hosts` (requires `uuid`) | `DELETE /api/hosts/{uuid}` |
| users | `GET /api/users` → `.response.users[]` | `POST /api/users` | `PATCH /api/users` (accepts `uuid` or `username`) | `DELETE /api/users/{uuid}` |
| subscription-settings | `GET /api/subscription-settings` → `.response` (singleton) | — | `PATCH /api/subscription-settings` (requires `uuid`) | — |

### Key Fields (for matching desired vs existing)

- config-profiles: `uuid` (already in JSON)
- internal-squads: `uuid` (already in JSON)
- nodes: `name`
- hosts: `remark`
- users: `username`

### Config Files

All in `vpn/nix/containers/remnapanel/configs/`:
- `config-profiles.json` — array, has `uuid` + `name` + `config`
- `internal-squads.json` — array, has `uuid` + `name` + `inbounds`
- `nodes.json` — array, has `name` + `address` + `port` + `countryCode` + `configProfile`
- `hosts.json` — array, has `inbound` + `remark` + `address` + `port` + `isDisabled`
- `users.json` — array, has `username` + `status` + `trafficLimitBytes` + `trafficLimitStrategy` + `expireAt` + `activeInternalSquads`
- `additional-settings.json` — object with `subscriptionSettings` key

### Existing Files

- `vpn/nix/containers/remnapanel/sync.nix` — **rewrite completely** (currently 428 lines of bash)
- New file: `vpn/nix/containers/remnapanel/sync.py`

---

### Task 1: Create Python sync script — API client and health check

**Files:**
- Create: `vpn/nix/containers/remnapanel/sync.py`

**Step 1: Write the base script with imports, API client class, and health check**

```python
#!/usr/bin/env python3
"""Remnawave declarative sync — reconciles JSON configs with the Remnawave API."""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import requests


class RemnawaveAPI:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update(
            {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        )

    def health_check(self, max_attempts: int = 30, interval: int = 10) -> bool:
        for i in range(1, max_attempts + 1):
            try:
                r = requests.get(
                    f"{self.base_url}/system/health", timeout=5
                )
                if r.ok:
                    return True
            except requests.ConnectionError:
                pass
            print(f"Waiting for API... ({i}/{max_attempts})", flush=True)
            time.sleep(interval)
        return False

    def get(self, endpoint: str) -> dict:
        r = self.session.get(f"{self.base_url}{endpoint}")
        r.raise_for_status()
        return r.json()

    def post(self, endpoint: str, data: dict) -> dict:
        r = self.session.post(f"{self.base_url}{endpoint}", json=data)
        r.raise_for_status()
        return r.json()

    def patch(self, endpoint: str, data: dict) -> dict:
        r = self.session.patch(f"{self.base_url}{endpoint}", json=data)
        r.raise_for_status()
        return r.json()

    def delete(self, endpoint: str) -> dict:
        r = self.session.delete(f"{self.base_url}{endpoint}")
        r.raise_for_status()
        return r.json()
```

**Step 2: Commit**

```bash
git add vpn/nix/containers/remnapanel/sync.py
git commit -m "feat(vpn): add sync.py with API client and health check"
```

---

### Task 2: Add entity definitions and reconcile logic

**Files:**
- Modify: `vpn/nix/containers/remnapanel/sync.py`

**Step 1: Add entity definitions and the reconcile function after the API class**

```python
ENTITIES = [
    {
        "name": "config-profiles",
        "file": "config-profiles.json",
        "endpoint": "/config-profiles",
        "key": "uuid",
        "list_path": None,  # no GET needed, PATCH directly with uuid from JSON
        "ops": ["update"],
        "update_fields": lambda item: {"uuid": item["uuid"], "config": item["config"]},
    },
    {
        "name": "internal-squads",
        "file": "internal-squads.json",
        "endpoint": "/internal-squads",
        "key": "uuid",
        "list_path": "response.internalSquads",
        "ops": ["update"],
        "update_fields": lambda item, uuid: {"uuid": uuid, "inbounds": item["inbounds"]},
    },
    {
        "name": "nodes",
        "file": "nodes.json",
        "endpoint": "/nodes",
        "key": "name",
        "list_path": "response",
        "ops": ["create", "update", "delete"],
    },
    {
        "name": "hosts",
        "file": "hosts.json",
        "endpoint": "/hosts",
        "key": "remark",
        "list_path": "response",
        "ops": ["create", "update", "delete"],
    },
    {
        "name": "users",
        "file": "users.json",
        "endpoint": "/users",
        "key": "username",
        "list_path": "response.users",
        "ops": ["create", "update", "delete"],
    },
]


def resolve_path(data: dict, path: str):
    """Navigate nested dict by dot-separated path."""
    for part in path.split("."):
        data = data[part]
    return data


def reconcile(api: RemnawaveAPI, entity: dict, desired: list, dry_run: bool) -> dict:
    """Reconcile desired state with API. Returns {"created": N, "updated": N, "deleted": N}."""
    stats = {"created": 0, "updated": 0, "deleted": 0}
    name = entity["name"]
    endpoint = entity["endpoint"]
    key = entity["key"]
    ops = entity["ops"]

    # Special case: config-profiles — no GET, PATCH each directly
    if name == "config-profiles":
        for item in desired:
            fields = entity["update_fields"](item)
            if dry_run:
                print(f"  [dry-run] UPDATE {name}: {item.get('name', item.get('uuid'))}")
            else:
                api.patch(endpoint, fields)
                print(f"  updated {name}: {item.get('name', item.get('uuid'))}")
            stats["updated"] += 1
        return stats

    # GET existing state
    existing_data = api.get(endpoint)
    existing_list = resolve_path(existing_data, entity["list_path"])
    existing_by_key = {item[key]: item for item in existing_list}
    desired_keys = set()

    for item in desired:
        key_value = item[key]
        desired_keys.add(key_value)

        if key_value in existing_by_key:
            if "update" in ops:
                existing = existing_by_key[key_value]
                uuid = existing["uuid"]
                if "update_fields" in entity:
                    fields = entity["update_fields"](item, uuid)
                else:
                    fields = {**item, "uuid": uuid}
                if dry_run:
                    print(f"  [dry-run] UPDATE {name}: {key_value}")
                else:
                    api.patch(endpoint, fields)
                    print(f"  updated {name}: {key_value}")
                stats["updated"] += 1
        else:
            if "create" in ops:
                if dry_run:
                    print(f"  [dry-run] CREATE {name}: {key_value}")
                else:
                    api.post(endpoint, item)
                    print(f"  created {name}: {key_value}")
                stats["created"] += 1

    # DELETE objects not in desired state
    if "delete" in ops:
        for key_value, existing in existing_by_key.items():
            if key_value not in desired_keys:
                uuid = existing["uuid"]
                if dry_run:
                    print(f"  [dry-run] DELETE {name}: {key_value} (uuid: {uuid})")
                else:
                    api.delete(f"{endpoint}/{uuid}")
                    print(f"  deleted {name}: {key_value}")
                stats["deleted"] += 1

    return stats
```

**Step 2: Commit**

```bash
git add vpn/nix/containers/remnapanel/sync.py
git commit -m "feat(vpn): add entity definitions and reconcile logic"
```

---

### Task 3: Add subscription settings sync and main function

**Files:**
- Modify: `vpn/nix/containers/remnapanel/sync.py`

**Step 1: Add subscription settings handler and main function at the end of the file**

```python
def sync_subscription_settings(api: RemnawaveAPI, settings: dict, dry_run: bool) -> dict:
    """Handle the singleton subscription-settings entity."""
    stats = {"created": 0, "updated": 0, "deleted": 0}
    sub_settings = settings.get("subscriptionSettings")
    if not sub_settings:
        return stats

    if dry_run:
        print("  [dry-run] UPDATE subscription-settings")
        stats["updated"] = 1
        return stats

    current = api.get("/subscription-settings")
    uuid = current["response"]["uuid"]
    api.patch("/subscription-settings", {**sub_settings, "uuid": uuid})
    print("  updated subscription-settings")
    stats["updated"] = 1
    return stats


def backup_database():
    """Run DB backup via systemd service. Exits on failure."""
    print("Backing up database...", flush=True)
    result = subprocess.run(
        ["systemctl", "start", "remnawave-db-backup.service"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Database backup failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    print("Database backup completed.", flush=True)


def main():
    parser = argparse.ArgumentParser(description="Remnawave declarative sync")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true", help="Show plan without applying")
    mode.add_argument("--apply", action="store_true", help="Apply changes")
    parser.add_argument("--no-backup", action="store_true", help="Skip DB backup before apply")
    args = parser.parse_args()

    api_url = os.environ.get("REMNAWAVE_API_URL", "https://rolder.net/api")
    api_token = os.environ.get("REMNAWAVE_API_TOKEN")
    configs_dir = os.environ.get("REMNAWAVE_CONFIGS_DIR", ".")

    if not api_token:
        print("REMNAWAVE_API_TOKEN is required", file=sys.stderr)
        sys.exit(1)

    api = RemnawaveAPI(api_url, api_token)

    if not api.health_check():
        print("API not available after 5 minutes", file=sys.stderr)
        sys.exit(1)

    if args.apply and not args.no_backup:
        backup_database()

    dry_run = args.dry_run
    prefix = "[DRY RUN] " if dry_run else ""
    print(f"{prefix}Starting sync...", flush=True)

    total = {"created": 0, "updated": 0, "deleted": 0}

    for entity in ENTITIES:
        config_path = Path(configs_dir) / entity["file"]
        if not config_path.exists():
            print(f"  skipping {entity['name']}: {config_path} not found")
            continue

        desired = json.loads(config_path.read_text())
        print(f"Syncing {entity['name']}...", flush=True)
        stats = reconcile(api, entity, desired, dry_run)
        for k in total:
            total[k] += stats[k]

    settings_path = Path(configs_dir) / "additional-settings.json"
    if settings_path.exists():
        print("Syncing subscription-settings...", flush=True)
        settings = json.loads(settings_path.read_text())
        stats = sync_subscription_settings(api, settings, dry_run)
        for k in total:
            total[k] += stats[k]

    print(
        f"\n{prefix}Done: {total['created']} created, "
        f"{total['updated']} updated, {total['deleted']} deleted",
        flush=True,
    )


if __name__ == "__main__":
    main()
```

**Step 2: Commit**

```bash
git add vpn/nix/containers/remnapanel/sync.py
git commit -m "feat(vpn): add main function with CLI, backup, and settings sync"
```

---

### Task 4: Rewrite sync.nix — replace 6 services with one

**Files:**
- Rewrite: `vpn/nix/containers/remnapanel/sync.nix` (replace all 428 lines)

**Step 1: Rewrite sync.nix completely**

```nix
# Remnawave API synchronization service
{
  pkgs,
  remnawave_api_token,
  ...
}:

let
  syncScript = pkgs.writers.writePython3Bin "remnawave-sync" {
    libraries = [ pkgs.python3Packages.requests ];
  } (builtins.readFile ./sync.py);
in
{
  systemd.services.remnawave-sync = {
    description = "Sync declarative config to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
    ];
    wants = [ "podman-remnawave-backend.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
    };

    environment = {
      REMNAWAVE_API_TOKEN = remnawave_api_token;
      REMNAWAVE_API_URL = "https://rolder.net/api";
      REMNAWAVE_CONFIGS_DIR = "${./configs}";
    };

    path = [ pkgs.systemd ];

    script = ''
      ${syncScript}/bin/remnawave-sync --apply
    '';
  };
}
```

Note: `path = [ pkgs.systemd ]` is needed so the Python script can call `systemctl` for DB backup.

**Step 2: Commit**

```bash
git add vpn/nix/containers/remnapanel/sync.nix
git commit -m "feat(vpn): replace 6 bash sync services with one Python script"
```

---

### Task 5: Test locally with dry-run

**Step 1: Build the NixOS configuration to check for syntax/build errors**

```bash
cd /home/decard/nix/vpn/nix
nix build .#nixosConfigurations.remnapanel.config.system.build.toplevel --dry-run
```

Expected: build plan without errors.

**Step 2: Test the Python script standalone with dry-run**

```bash
export REMNAWAVE_API_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiYTg1YjZkMDEtOTUyNS00Mjg3LTk3ZDYtMmVkZjg4ZWVlYTZiIiwidXNlcm5hbWUiOm51bGwsInJvbGUiOiJBUEkiLCJpYXQiOjE3NTE5OTI0ODcsImV4cCI6MTAzOTE5MDYwODd9.xRzDMZ7iInTXWK_cJtSM74hdC1wmkHYmlSAsO3q0MRc"
export REMNAWAVE_API_URL="https://rolder.net/api"
export REMNAWAVE_CONFIGS_DIR="/home/decard/nix/vpn/nix/containers/remnapanel/configs"

nix-shell -p python3 python3Packages.requests --run "python3 /home/decard/nix/vpn/nix/containers/remnapanel/sync.py --dry-run"
```

Expected: plan showing UPDATE for all existing entities, no CREATE or DELETE.

**Step 3: Commit any fixes if needed**

---

### Task 6: Deploy to remnapanel server

**Step 1: Deploy**

```bash
NIX_SSHOPTS="-p 4444 -i ~/.ssh/rolder-net-gcp" nixos-rebuild switch --refresh --flake /home/decard/nix/vpn/nix#remnapanel --target-host rolder@34.51.236.162 --sudo
```

**Step 2: Verify old services are gone and new one is active**

```bash
ssh -p 4444 -i ~/.ssh/rolder-net-gcp rolder@34.51.236.162 "systemctl status remnawave-sync; systemctl status remnawave-config-profiles-sync 2>&1 || true"
```

Expected: `remnawave-sync` active/succeeded, old services not found.

**Step 3: Check journal logs**

```bash
ssh -p 4444 -i ~/.ssh/rolder-net-gcp rolder@34.51.236.162 "journalctl -u remnawave-sync --no-pager -n 50"
```

**Step 4: Verify panel data is intact**

Open `https://rolder.net` — check nodes, hosts, users, squads, settings are all present.

**Step 5: Commit**

```bash
git commit --allow-empty -m "feat(vpn): deploy and verify remnawave sync redesign"
```
