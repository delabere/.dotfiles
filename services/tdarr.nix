{ lib, ... }:

{
  services.tdarr = {
    enable = true;
    dataDir = "/data/.state/tdarr";
    group = "media";

    # Match the other media services: expose the UI on the home network so it
    # can be opened directly from Homepage. Do not publish this port externally.
    server = {
      serverIP = "0.0.0.0";
      serverBindIP = true;
    };

    nodes.main = {
      # Configure the first library and flow before allowing work to start.
      startPaused = true;
      workers = {
        transcodeCPU = 1;
        transcodeGPU = 0;
        healthcheckCPU = 1;
        healthcheckGPU = 0;
      };
    };
  };

  # Tdarr runs with the media group as its primary group. The supplementary
  # groups expose the AMD render device for optional VAAPI transcoding.
  users.users.tdarr.extraGroups = [ "render" "video" ];

  systemd.tmpfiles.rules = [
    "d /data/.state/tdarr/nodes 0750 tdarr media -"
    "d /data/.state/tdarr/nodes/main 0750 tdarr media -"
    "d /data/.state/tdarr/nodes/main/configs 0750 tdarr media -"
    "d /mnt/bigboi/tdarr-cache 2770 tdarr media -"
  ];

  # The upstream NixOS module hardens the node with ProtectSystem=strict, so
  # explicitly grant writes only to the libraries and transcode cache.
  systemd.services.tdarr-node-main.serviceConfig.ReadWritePaths = lib.mkAfter [
    "/mnt/bigboi/PlexMedia/Movies"
    "/mnt/bigboi/PlexMedia/TV"
    "/mnt/bigboi/tdarr-cache"
  ];
}
