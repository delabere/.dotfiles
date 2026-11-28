{ config, pkgs, lib, ... }:
# Nightly restic backups of brain's service state (not Plex, Tdarr, Jellyfin or Terminus).
#   local:   /mnt/external/restic/brain
#   offsite: Google Drive via rclone
# Restore steps: docs/restore-brain.md
let
  prepareDir = "/var/backup/prepare";

  # Consistent copies of live databases, taken just before each backup.
  prepare = pkgs.writeShellScript "backup-prepare" ''
    set -euo pipefail
    install -d -m 0700 ${prepareDir}
    # Home Assistant recorder (SQLite): online, consistent copy
    ${pkgs.sqlite}/bin/sqlite3 /data/.state/home-assistant/home-assistant_v2.db \
      ".backup '${prepareDir}/home-assistant_v2.db'"
    # Hermes session history (SQLite, written live by the gateway)
    if [ -f /var/lib/hermes/.hermes/state.db ]; then
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/hermes/.hermes/state.db \
        ".backup '${prepareDir}/hermes-state.db'"
    fi
    # Terminus is deliberately not backed up; remove any dump left by earlier runs
    rm -f ${prepareDir}/terminus_production.sql
  '';

  vols = "/var/lib/docker/volumes";

  common = {
    passwordFile = config.age.secrets.restic-password.path;
    initialize = true;
    backupPrepareCommand = "${prepare}";
    extraBackupArgs = [ "--exclude-caches" ];
    exclude = [
      # live databases: the consistent copies in ${prepareDir} are backed up instead
      "/data/.state/home-assistant/home-assistant_v2.db"
      "/data/.state/home-assistant/home-assistant_v2.db-wal"
      "/data/.state/home-assistant/home-assistant_v2.db-shm"
      "/var/lib/hermes/.hermes/state.db"
      "/var/lib/hermes/.hermes/state.db-wal"
      "/var/lib/hermes/.hermes/state.db-shm"
      # Hermes caches and the nix store pointers it recreates on start
      "/var/lib/hermes/.hermes/cache"
      "/var/lib/hermes/.cache"   # downloaded Whisper models (re-downloaded on demand)
      "/var/lib/hermes/.npm"     # npx package cache
      "/var/lib/hermes/current-package"
      "/var/lib/hermes/current-entrypoint"
      "/var/lib/hermes/.gc-root"
      # Terminus (TRMNL server): not backed up at all
      "${vols}/terminus_*"
      # sockets and IPC, meaningless after restore
      "${vols}/*-ipc"
      "${vols}/*-socket"
      # media servers: libraries can be rebuilt by rescanning, not worth backing up
      "/data/.state/plex"
      "/data/.state/tdarr"
      "/data/.state/nixarr/jellyfin"
      # logs
      "*.log"
    ];
  };

  essentialPaths = [
    "/data/.state"
    vols
    prepareDir
    "/var/lib/tailscale"
    # Hermes: memory, skills, cron jobs, OAuth tokens (Google, Notion,
    # Todoist); its state.db comes from the consistent copy in prepareDir
    "/var/lib/hermes"
  ];
in
{
  age.secrets.restic-password.file = ./../secrets/restic-password.age;
  age.secrets.rclone-conf.file = ./../secrets/rclone-conf.age;

  environment.systemPackages = [ pkgs.restic ];

  services.restic.backups = {
    local = common // {
      repository = "/mnt/external/restic/brain";
      paths = essentialPaths;
      timerConfig = { OnCalendar = "03:30"; Persistent = true; RandomizedDelaySec = "10m"; };
      pruneOpts = [ "--keep-daily 14" "--keep-weekly 8" "--keep-monthly 12" ];
    };

    offsite = common // {
      repository = "rclone:gdrive:backups/brain-restic";
      rcloneConfigFile = config.age.secrets.rclone-conf.path;
      # Google Drive rate-limits API calls per minute (hard on rclone's shared client_id):
      # bigger pack files mean fewer uploads, and rclone is capped at 4 requests/s.
      extraBackupArgs = common.extraBackupArgs ++ [ "--pack-size=64" ];
      extraOptions = [ "rclone.args='serve restic --stdio --tpslimit 4 --tpslimit-burst 4'" ];
      paths = essentialPaths;
      timerConfig = { OnCalendar = "04:30"; Persistent = true; RandomizedDelaySec = "10m"; };
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6" ];
    };
  };

  # Backups must not compete with HA/Plex during the day; they run at night anyway.
  systemd.services.restic-backups-local.serviceConfig = { Nice = 10; IOSchedulingClass = "idle"; };
  systemd.services.restic-backups-offsite.serviceConfig = { Nice = 10; IOSchedulingClass = "idle"; };
}
