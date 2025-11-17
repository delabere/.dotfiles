{ config, pkgs, ... }: {

  age.secrets = {
    "wg.conf" = {
      file = ./../secrets/nordvpn-wireguard.conf.age;
    };
  };

  nixarr = {
    enable = true;
    vpn = {
      enable = true;
      wgConf = config.age.secrets."wg.conf".path;
    };
    # jellyfin.enable = true;
    radarr.enable = true;
    bazarr.enable = true;
    prowlarr.enable = true;
    sonarr.enable = true;
    transmission = {
      enable = true;
      flood.enable = true;
      vpn.enable = true;
      openFirewall = true;
      extraSettings = {
        download-dir = "/mnt/bigboi/torrents";
        incomplete-dir = "/mnt/bigboi/torrents/.incomplete";
        # peer-port-random-on-start = true;
        ratio-limit-enabled = true;
        ratio-limit = 1;
        download-queue-size = 15;
      };
    };
  };

  # services.flaresolverr.enable = true;
  # services.flaresolverr.openFirewall = true;

  # not provided by nixarr, but it makes sense to live here
  services.plex = {
    enable = true;
    dataDir = "/data/.state/plex";
    openFirewall = true;
  };


  #   virtualisation = {
  #     podman = {
  #       enable = true;
  #
  #       # Create a `docker` alias for podman, to use it as a drop-in replacement
  #       dockerCompat = true;
  #
  #       # Required for containers under podman-compose to be able to talk to each other.
  #       defaultNetwork.settings.dns_enabled = true;
  #     };
  #
  #     # the flare-solverr package is not working on nix for darwin yet:
  #     # https://github.com/NixOS/nixpkgs/issues/294789#issuecomment-2016820757
  #     oci-containers = {
  #       backend = "podman";
  #       containers = {
  #         flare-solvarr = {
  #           image = "ghcr.io/flaresolverr/flaresolverr:latest";
  #           autoStart = true;
  #           ports = [ "127.0.0.1:8191:8191" ];
  #           environment = {
  #             LOG_LEVEL = "info";
  #             LOG_HTML = "false";
  #             CAPTCHA_SOLVER = "hcaptcha-solver";
  #             # TZ = "America/New_York";
  #           };
  #         };
  #       };
  #     };
  #   };
}
