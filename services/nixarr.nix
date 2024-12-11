{ config, pkgs, ... }: {

  nixarr = {
    enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    sonarr.enable = true;
    transmission.enable = true;
  };
}
