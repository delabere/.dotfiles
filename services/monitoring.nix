{ config, pkgs, ... }: {

  services.grafana = {
    enable = true;
    settings = {
      server = {
        port = 3000;
        domain = "localhost";
        protocol = "http";
        dataDir = "/var/lib/grafana";
        http_addr = "";
      };
    };
  };

  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "chrysalis";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };
}
