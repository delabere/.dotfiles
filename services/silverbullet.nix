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

  # we can move this out of silverbullet.nix later when it becomes a permanenet fixture
  services.karakeep.enable = true;
  services.karakeep.extraEnvironment = {
    PORT = "4000";
    OPENAI_API_KEY = "";
  };

}


