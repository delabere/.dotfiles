{ config, pkgs, ... }: {

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.docker.daemon.settings = {
    data-root = "/data/docker";
  };
  users.users.delabere.extraGroups = [ "docker" ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {

      hackagecompare = {
        image = "chrissound/hackagecomparestats-webserver:latest";
        ports = [ "127.0.0.1:3010:3010" ];
        volumes = [
          "/root/hackagecompare/packageStatistics.json:/root/hackagecompare/packageStatistics.json"
        ];
        cmd = [
          "--base-url"
          "\"/hackagecompare\""
        ];
      };
    };

  };
};
}
