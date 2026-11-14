# Restoring brain (or moving it to a new server)

Everything that defines brain lives in this repo. What can't be code (logins, device
pairings, history, service data) is in the nightly restic backups.

## What lives where

| What | Where |
|---|---|
| Services, packages, Home Assistant integrations, templates, sensors | `services/*.nix`, `machines/brain/` |
| HA automations, scenes, helpers, template helpers, Main dashboard | `services/home-assistant/config/` (linked into HA as `nix/`) |
| HA logins & pairings (Octopus, Tado, HomeKit, Shelly, phones…), history, logs | backups: `/data/.state/home-assistant` |
| Vellum, Terminus, n8n, MinusPod, *arr configs, Tailscale identity | backups |
| Secrets (Tailscale key, backup password, rclone config…) | `secrets/*.age` (agenix) |

## Backups

Defined in `services/backup.nix`.

- **local**: `/mnt/external/restic/brain`, nightly ~03:30, keeps 14 daily / 8 weekly / 12 monthly
- **offsite**: Google Drive `backups/brain-restic` (rclone remote `gdrive`), nightly ~04:30, keeps 7 / 4 / 6.
  Excludes rebuildable Plex/Tdarr/Jellyfin library data.

Before each run, `backup-prepare` writes consistent copies of live databases to
`/var/backup/prepare` (HA recorder via `sqlite3 .backup`, Terminus via `pg_dump`); those copies
are backed up instead of the live files.

The backup password is `secrets/restic-password.age`. It can be decrypted on brain **and on the
Mac** (`agenix -d secrets/restic-password.age -i ~/.ssh/id_ed25519`), so losing brain doesn't lose
the password. Keep a copy in 1Password too.

Useful commands on brain:

```sh
sudo restic-local snapshots          # list local snapshots
sudo restic-offsite snapshots        # list Google Drive snapshots
sudo systemctl start restic-backups-local     # back up now
journalctl -u restic-backups-local -e         # last run's log
```

(`restic-local` / `restic-offsite` are wrappers NixOS creates with the repository and password set.)

## Restore onto a new server

1. **Install NixOS** and give the machine SSH access for `delabere`.
2. **Secrets**: agenix decrypts with the host's SSH key. A new machine has a new host key, so add
   it to `secrets/secrets.nix` (`brain-system`) and re-key from the Mac:
   ```sh
   cd secrets && agenix -r -i ~/.ssh/id_ed25519
   ```
3. **Hardware**: generate `machines/brain/hardware-configuration.nix` on the new machine
   (`nixos-generate-config --show-hardware-config`) and update disk UUIDs / mounts
   (`/mnt/bigboi`, `/mnt/external`).
4. **Deploy** from the Mac: `build-brain` (or `nixos-rebuild switch --flake .#brain` on the box).
   Services start empty at this point; that's expected.
5. **Restore data** (stop services that own it first):
   ```sh
   sudo systemctl stop home-assistant docker
   sudo restic-offsite snapshots                       # or restic-local if the external disk survived
   sudo restic-offsite restore latest --target / \
     --include /data/.state --include /var/lib/docker/volumes --include /var/lib/tailscale \
     --include /var/backup/prepare
   ```
6. **Put the database copies back**:
   ```sh
   sudo cp /var/backup/prepare/home-assistant_v2.db /data/.state/home-assistant/
   sudo chown hass:hass /data/.state/home-assistant/home-assistant_v2.db
   sudo systemctl start docker
   # Terminus: once terminus-database is up
   sudo docker exec -i terminus-database psql -U terminus terminus_production < /var/backup/prepare/terminus_production.sql
   ```
7. **Start Home Assistant**: `sudo systemctl start home-assistant`. Logins, pairings, dashboards
   and automations come back as they were.
8. **Network things to check**: brain's LAN IP (`192.168.1.11` is referenced by Terminus
   `API_URI` and DNS/Caddy records), the Tailscale route approval (`192.168.1.0/24`), and the
   router's port forwards.

## Editing Home Assistant config

- Repo-managed (read-only in the app): everything in `services/home-assistant/config/`.
  Edit the files, then `build-brain`.
- Things made in the app go to the **UI area** (`automations.yaml`, `scenes.yaml` in HA's own
  config dir). They're backed up, and can be moved into the repo later.
