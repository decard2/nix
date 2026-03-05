"""Remnawave panel reconcile tool.

Replaces per-entity bash systemd services with a single declarative sync
that reads desired state from JSON files and reconciles it against the
Remnawave API.
"""

import argparse
import json
import os
import subprocess
import sys
import time

import requests

# ---------------------------------------------------------------------------
# API client
# ---------------------------------------------------------------------------


class RemnawaveAPI:
    """Thin wrapper around the Remnawave REST API."""

    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            }
        )

    def health_check(self, max_attempts: int = 30, interval: int = 10) -> bool:
        """Poll /system/health until the API is reachable."""
        for attempt in range(1, max_attempts + 1):
            try:
                resp = self.session.get(f"{self.base_url}/system/health")
                if resp.ok:
                    print("API is healthy.")
                    return True
            except requests.ConnectionError:
                pass
            print(
                f"Health check attempt {attempt}/{max_attempts}"
                f" failed, retrying in {interval}s ..."
            )
            time.sleep(interval)
        print("ERROR: API did not become healthy in time.")
        return False

    def get(self, endpoint: str) -> dict:
        resp = self.session.get(f"{self.base_url}{endpoint}")
        resp.raise_for_status()
        return resp.json()

    def post(self, endpoint: str, data: dict) -> dict:
        resp = self.session.post(f"{self.base_url}{endpoint}", json=data)
        resp.raise_for_status()
        return resp.json()

    def patch(self, endpoint: str, data: dict) -> dict:
        resp = self.session.patch(f"{self.base_url}{endpoint}", json=data)
        resp.raise_for_status()
        return resp.json()

    def delete(self, endpoint: str) -> dict:
        resp = self.session.delete(f"{self.base_url}{endpoint}")
        resp.raise_for_status()
        return resp.json()


# ---------------------------------------------------------------------------
# Entity definitions
# ---------------------------------------------------------------------------

def _config_profile_fields(item):
    return {
        "uuid": item["uuid"],
        "config": item["config"],
    }


def _internal_squad_fields(item, uuid):
    return {
        "uuid": uuid,
        "inbounds": item["inbounds"],
    }


ENTITIES = [
    {
        "name": "config-profiles",
        "file": "config-profiles.json",
        "endpoint": "/config-profiles",
        "key": "uuid",
        "list_path": None,
        "ops": ["update"],
        "update_fields": _config_profile_fields,
    },
    {
        "name": "internal-squads",
        "file": "internal-squads.json",
        "endpoint": "/internal-squads",
        "key": "uuid",
        "list_path": "response.internalSquads",
        "ops": ["update"],
        "update_fields": _internal_squad_fields,
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


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def resolve_path(data: dict, path: str):
    """Navigate a nested dict by a dot-separated path."""
    for part in path.split("."):
        data = data[part]
    return data


# ---------------------------------------------------------------------------
# Reconcile
# ---------------------------------------------------------------------------


def reconcile(
    api: RemnawaveAPI,
    entity: dict,
    desired: list,
    dry_run: bool,
) -> dict:
    """Reconcile a single entity type against the API.

    Returns a stats dict with keys created, updated, deleted.
    """
    stats = {"created": 0, "updated": 0, "deleted": 0}
    name = entity["name"]
    endpoint = entity["endpoint"]
    key = entity["key"]
    ops = entity["ops"]

    # --- Special case: config-profiles (no GET, PATCH directly) -----------
    if entity["list_path"] is None:
        for item in desired:
            payload = entity["update_fields"](item)
            if dry_run:
                print(f"  [dry-run] PATCH {endpoint} uuid={payload['uuid']}")
            else:
                api.patch(endpoint, payload)
                print(f"  Updated {name} uuid={payload['uuid']}")
            stats["updated"] += 1
        return stats

    # --- General case: GET existing, then create/update/delete ------------
    existing_list = resolve_path(api.get(endpoint), entity["list_path"])
    existing_by_key = {item[key]: item for item in existing_list}
    desired_by_key = {item[key]: item for item in desired}

    # Create
    if "create" in ops:
        for k, item in desired_by_key.items():
            if k not in existing_by_key:
                if dry_run:
                    print(f"  [dry-run] CREATE {name} {key}={k}")
                else:
                    api.post(endpoint, item)
                    print(f"  Created {name} {key}={k}")
                stats["created"] += 1

    # Update
    if "update" in ops:
        for k, item in desired_by_key.items():
            if k in existing_by_key:
                existing = existing_by_key[k]
                uuid = existing["uuid"]
                if "update_fields" in entity:
                    payload = entity["update_fields"](item, uuid)
                else:
                    payload = {**item, "uuid": uuid}
                if dry_run:
                    print(f"  [dry-run] UPDATE {name} {key}={k} uuid={uuid}")
                else:
                    api.patch(endpoint, payload)
                    print(f"  Updated {name} {key}={k} uuid={uuid}")
                stats["updated"] += 1

    # Delete
    if "delete" in ops:
        for k, existing in existing_by_key.items():
            if k not in desired_by_key:
                uuid = existing["uuid"]
                if dry_run:
                    print(f"  [dry-run] DELETE {name} {key}={k} uuid={uuid}")
                else:
                    api.delete(f"{endpoint}/{uuid}")
                    print(f"  Deleted {name} {key}={k} uuid={uuid}")
                stats["deleted"] += 1

    return stats


# ---------------------------------------------------------------------------
# Subscription settings
# ---------------------------------------------------------------------------


def sync_subscription_settings(
    api: RemnawaveAPI,
    settings: dict,
    dry_run: bool,
) -> dict:
    """Sync subscription settings from the provided dict."""
    if "subscriptionSettings" not in settings:
        return {"created": 0, "updated": 0, "deleted": 0}

    sub_settings = settings["subscriptionSettings"]
    existing = api.get("/subscription-settings")
    uuid = resolve_path(existing, "response.uuid")
    payload = {**sub_settings, "uuid": uuid}

    if dry_run:
        print("  [dry-run] PATCH /subscription-settings")
    else:
        api.patch("/subscription-settings", payload)
        print("  Updated subscription settings.")

    return {"created": 0, "updated": 1, "deleted": 0}


# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------


def backup_database() -> None:
    """Trigger a database backup via systemd."""
    print("Starting database backup ...")
    result = subprocess.run(
        ["systemctl", "start", "remnawave-db-backup.service"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Database backup failed:\n{result.stderr}")
        sys.exit(1)
    print("Database backup completed.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(description="Remnawave reconcile tool")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned changes without applying",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes to the API",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip database backup before apply",
    )
    args = parser.parse_args()

    dry_run = args.dry_run

    base_url = os.environ.get("REMNAWAVE_API_URL", "https://rolder.net/api")
    token = os.environ.get("REMNAWAVE_API_TOKEN")
    configs_dir = os.environ.get("REMNAWAVE_CONFIGS_DIR", ".")

    if not token:
        print("ERROR: REMNAWAVE_API_TOKEN must be set.")
        sys.exit(1)

    api = RemnawaveAPI(base_url, token)

    # Health check
    if not api.health_check():
        print("Aborting: API health check failed.")
        sys.exit(1)

    # Backup (only in apply mode)
    if args.apply and not args.no_backup:
        backup_database()

    # Reconcile entities
    summary = {}
    for entity in ENTITIES:
        filepath = os.path.join(configs_dir, entity["file"])
        if not os.path.exists(filepath):
            print(f"Skipping {entity['name']}: {filepath} not found")
            continue

        with open(filepath) as f:
            desired = json.load(f)

        print(f"\n--- {entity['name']} ---")
        stats = reconcile(api, entity, desired, dry_run)
        summary[entity["name"]] = stats

    # Subscription settings
    settings_path = os.path.join(configs_dir, "additional-settings.json")
    if os.path.exists(settings_path):
        print("\n--- subscription-settings ---")
        with open(settings_path) as f:
            settings = json.load(f)
        sub_stats = sync_subscription_settings(api, settings, dry_run)
        summary["subscription-settings"] = sub_stats
    else:
        print(f"\nSkipping subscription-settings: {settings_path} not found")

    # Summary
    print("\n=== Summary ===")
    if dry_run:
        print("(dry-run mode — no changes were applied)\n")
    for name, stats in summary.items():
        parts = [f"{k}: {v}" for k, v in stats.items() if v > 0]
        line = ", ".join(parts) if parts else "no changes"
        print(f"  {name}: {line}")
    print()


if __name__ == "__main__":
    main()
