# Review page for the China 2026 film: watch a rendered version, leave time-stamped comments,
# and compare before/after for each change. Tailscale-only: https://brain.degu-vega.ts.net:8444
#   /          -> static page (services/china-review/index.html)
#   /media/*   -> renders + manifests on the share (China2026Edit/Review/<version>/...)
#   /api/*     -> tiny comments API (services/china-review/api.py), comments in /var/lib/china-review
{ pkgs, ... }:
let
  reviewDir = "/mnt/bigboi/share/China2026Edit/Review";
  site = ./china-review;
in
{
  systemd.services.china-review-api = {
    description = "China 2026 review comments API";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = { PORT = "3031"; STATE_DIR = "/var/lib/china-review"; REVIEW_DIR = reviewDir; };
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${site}/api.py";
      DynamicUser = true;
      StateDirectory = "china-review";
      Restart = "on-failure";
      MemoryMax = "128M";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  services.caddy.virtualHosts."https://brain.degu-vega.ts.net:8444".extraConfig = ''
    handle /api/* {
      reverse_proxy 127.0.0.1:3031
    }
    handle_path /media/* {
      root * ${reviewDir}
      header Cache-Control "no-cache"
      file_server
    }
    handle {
      root * ${site}
      try_files {path} /index.html
      file_server
    }
  '';

  networking.firewall.allowedTCPPorts = [ 8444 ];
}
