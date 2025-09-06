{ config, pkgs, ... }: {
  services.silverbullet = {
    enable = true;
    openFirewall = true;
    listenPort = 4040;
    listenAddress = "0.0.0.0";
    spaceDir = "/home/delabere/notes";
    user = "delabere"; # files are stored in userspace
  };
  networking.firewall.allowedTCPPorts = [ 4040 ];
}


