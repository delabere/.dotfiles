{ config, lib, pkgs, ... }: {

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
    jellyfin.enable = true;
    radarr.enable = true;
    bazarr.enable = true;
    prowlarr = {
      enable = true;
      # Virgin Media blocks several public indexer domains at the TLS layer.
      # Route Prowlarr through the existing kill-switched WireGuard namespace.
      vpn.enable = true;
    };
    sonarr.enable = true;
    transmission = {
      enable = true;
      flood.enable = true;
      vpn.enable = true;
      peerPort = 51413;
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

  # Prowlarr uses FlareSolverr for indexers protected by Cloudflare. Keep it
  # loopback-only: it provides an unrestricted browser proxy and should never
  # be exposed to the LAN or internet.
  services.flaresolverr = {
    enable = true;
    openFirewall = false;
  };
  systemd.services.flaresolverr.environment = {
    HOST = "127.0.0.1";
    LOG_LEVEL = "info";
    LOG_HTML = "false";
    TZ = config.time.timeZone;
  };
  # Prowlarr and FlareSolverr must share a network namespace so that the
  # loopback-only proxy is reachable and both use the same VPN egress.
  systemd.services.flaresolverr.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  # Nixarr proxies VPN-confined Prowlarr through nginx. Its recommended proxy
  # headers use `$host`, which drops the non-standard :9696 port and makes
  # Prowlarr generate broken grab URLs. Reattach the fixed, trusted port.
  services.nginx.virtualHosts."127.0.0.1:9696".locations."/" = {
    recommendedProxySettings = lib.mkForce false;
    extraConfig = ''
      proxy_set_header Host $host:9696;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host:9696;
      proxy_set_header X-Forwarded-Server $hostname;
    '';
  };

  # not provided by nixarr, but it makes sense to live here
  services.plex = {
    enable = true;
    dataDir = "/data/.state/plex";
    openFirewall = true;
  };
}
