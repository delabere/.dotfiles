{ lib, pkgs, ... }:

{
  services.tdarr = {
    enable = true;
    dataDir = "/data/.state/tdarr";
    group = "media";

    server = {
      serverIP = "0.0.0.0";
      serverBindIP = true;
    };

    nodes.main = {
      startPaused = false;
      workers = {
        transcodeCPU = 1;
        transcodeGPU = 0;
        healthcheckCPU = 1;
        healthcheckGPU = 0;
      };
    };
  };

  users.users.tdarr.extraGroups = [ "render" "video" ];

  systemd.tmpfiles.rules = [
    "d /data/.state/tdarr/nodes 0750 tdarr media -"
    "d /data/.state/tdarr/nodes/main 0750 tdarr media -"
    "d /data/.state/tdarr/nodes/main/configs 0750 tdarr media -"
    "d /mnt/bigboi/tdarr-cache 2770 tdarr media -"
  ];

  # Community plugins install JavaScript dependencies at runtime and need a
  # POSIX shell in the otherwise hardened node service's PATH.
  systemd.services.tdarr-node-main.path = lib.mkAfter [ pkgs.bash ];

  systemd.services.tdarr-node-main.serviceConfig = {
    # Use idle CPU freely, but yield to interactive media services under load.
    CPUWeight = 10;
    Nice = 10;
    UMask = "0002";

    ReadWritePaths = lib.mkAfter [
      "/mnt/bigboi/PlexMedia/Movies"
      "/mnt/bigboi/PlexMedia/TV"
      "/mnt/bigboi/tdarr-cache"
    ];
  };

  # Tdarr performs the final cache-to-library move in the server process, not
  # the node process, so the server needs the same narrowly scoped write access.
  systemd.services.tdarr-server.serviceConfig = {
    UMask = "0002";
    ReadWritePaths = lib.mkAfter [
      "/mnt/bigboi/PlexMedia/Movies"
      "/mnt/bigboi/PlexMedia/TV"
      "/mnt/bigboi/tdarr-cache"
    ];
  };
}
