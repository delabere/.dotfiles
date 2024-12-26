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
    prowlarr.enable = true;
    sonarr.enable = true;
    transmission = {
      enable = true;
      flood.enable = true;
      vpn.enable = true;
      openFirewall = true;
      extraSettings = {
        ratio-limit-enabled = true;
        ratio-limit = 1;
      };
    };
  };


  # not provided by nixarr, but it makes sense to live here
  services.plex = {
    enable = true;
    dataDir = "/data/.state/plex";
    openFirewall = true;
  };

}
