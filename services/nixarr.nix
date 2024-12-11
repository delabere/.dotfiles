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
    radarr.enable = true;
    prowlarr.enable = true;
    sonarr.enable = true;
    transmission = {
      enable = true;
      vpn.enable = true;
    };
  };
}
