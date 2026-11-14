{ config, pkgs, lib, ... }:
# Nightly restic backups of brain's service state.
#   local:   /mnt/external/restic/brain   (everything, incl. rebuildable media metadata)
#   offsite: Google Drive via rclone      (everything except Plex/Tdarr/Jellyfin library data)
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
    # Terminus Postgres (container)
    if ${pkgs.docker}/bin/docker inspect terminus-database >/dev/null 2>&1; then
      ${pkgs.docker}/bin/docker exec terminus-database \
        pg_dump -U terminus terminus_production > ${prepareDir}/terminus_production.sql
    fi
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
      "${vols}/terminus_database-data"
      # sockets and IPC, meaningless after restore
      "${vols}/*-ipc"
      "${vols}/*-socket"
      # caches and logs
      "/data/.state/nixarr/jellyfin/cache"
      "/data/.state/nixarr/jellyfin/log"
      "/data/.state/plex/Plex Media Server/Cache"
      "/data/.state/plex/Plex Media Server/Logs"
      "/data/.state/plex/Plex Media Server/Crash Reports"
      "*.log"
    ];
  };

  essentialPaths = [
    "/data/.state"
    vols
    prepareDir
    "/var/lib/tailscale"
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
      exclude = common.exclude ++ [
        # rebuildable media-server libraries stay local only
        "/data/.state/plex"
        "/data/.state/tdarr"
        "/data/.state/nixarr/jellyfin/data"
        "/data/.state/nixarr/jellyfin/repair-backups"
      ];
      timerConfig = { OnCalendar = "04:30"; Persistent = true; RandomizedDelaySec = "10m"; };
      pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6" ];
    };
  };

  # Backups must not compete with HA/Plex during the day; they run at night anyway.
  systemd.services.restic-backups-local.serviceConfig = { Nice = 10; IOSchedulingClass = "idle"; };
  systemd.services.restic-backups-offsite.serviceConfig = { Nice = 10; IOSchedulingClass = "idle"; };
}
