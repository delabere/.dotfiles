{ config, pkgs, ... }: {
  services.silverbullet = {
    enable = true;
    openFirewall = true;
    listenPort = 4040;
  };
  networking.firewall.allowedTCPPorts = [ 4040 ];
}


