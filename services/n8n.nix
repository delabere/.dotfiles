{ ... }: {

  # systemd.services.n8n.environment = {
  #   N8N_SECURE_COOKIE = "false";
  #   N8N_RELEASE_TYPE = "dev";
  #   # N8N_EDITOR_BASE_URL = "http://degu-vega.ts.net";
  #   # WEBHOOK_URL = "http://brain.degu-vega.ts.net:5678";
  #   # N8N_SSL_CERT = "/home/delabere/.dotfiles/brain.degu-vega.ts.net.crtx";
  #   # N8N_SSL_CERT = ./brain.degu-vega.ts.net.crt;
  #   # N8N_SSL_KEY = "/home/delabere/.dotfiles/brain.degu-vega.ts.net.keyx";
  #   # N8N_SSL_KEY = ./brain.degu-vega.ts.net.key;
  #   # N8N_PROTOCOL = "https";
  #
  # };
  #
  # services.n8n = {
  #   enable = true;
  #   openFirewall = true;
  #
  # https://github.com/n8n-io/n8n/blob/master/packages/cli/src/config/schema.ts
  # settings = {
  # editorBaseUrl = "https://brain.degu-vega.ts.net:5678";
  # ssl_cert = "/home/delabere/.dotfiles/brain.degu-vega.ts.net.crtx";
  # ssl_key = "/home/delabere/.dotfiles/brain.degu-vega.ts.net.keyx";
  # };
  # webhookUrl = "https://brain.degu-vega.ts.net:5678";
  # };
  # n8n.nix
  # containers.n8n.bindMounts =
  #   {
  #     "/key.key" = {
  #       hostPath = ./brain.degu-vega.ts.net.key;
  #       isReadOnly = true;
  #     };
  #     "/cert.crt" = {
  #       hostPath = ./brain.degu-vega.ts.net.crt;
  #       isReadOnly = true;
  #     };
  #   };

  # virtualisation.docker.enable = true;

  # virtualisation.docker.enable = true;
  # virtualisation.docker.rootless = {
  #   enable = true;
  #   setSocketVariable = true;
  # };
  # virtualisation.docker.daemon.settings = {
  #   data-root = "/data/docker";
  # };
  # users.users.delabere.extraGroups = [ "docker" ];
  # virtualisation.oci-containers.backend = "docker";

  # allows the containers to find each other on the network using
  # http://supergateway:8000/sse for example
  virtualisation.podman.defaultNetwork.settings = {
    dns_enabled = true;
  };

  virtualisation.oci-containers.containers = {
    n8n = {
      image = "n8nio/n8n";
      volumes = [
        "n8n_data:/home/node/.n8n"
        # "/home/delabere/.dotfiles/services:/services"
      ];
      # ports = [ "5678:5678" ];
      # cmd = [ "--tunnel" ];

      ports = [ "5678:5678" ];
      # networks = [ "skynet" ];
      environment = {
        N8N_SECURE_COOKIE = "false";
        # N8N_SSL_CERT = "/services/brain.degu-vega.ts.net.crt";
        # N8N_SSL_KEY = "/services/brain.degu-vega.ts.net.key";
        # N8N_PROTOCOL = "https";
        # to get this working I run
        # sudo tailscale funnel 5678
        # but that needs to stay up
        # with a combination of env variables and a config files: https://tailscale.com/blog/docker-tailscale-guide
        # it seems possible to have this open up by default.
        # The other option here is to set up a reverse proxy which *might* be a better idea as it will 
        # be reusable for my other applications (generally a good idea)
        # if I can find a way to set up the reverse proxy configuration within the service config that would be a winner too

        # https://blog.kolaente.de/2024/10/making-tailscale-services-available-on-the-public-internet-with-nixos/ to read later
        WEBHOOK_URL = "https://n8n.delabere.com/"; # see caddy.nix
        # WEBHOOK_URL = "localhost:5678";
      };
      extraOptions = [
        "--rm" # Remove container when it exits
      ];
    };

    # supergateway = {
    #   image = "supercorp/supergateway";
    #   ports = [ "8000:8000" ];
    #
    #   cmd = [
    #     "--stdio"
    #     "npx -y @modelcontextprotocol/server-filesystem ."
    #     "--port"
    #     "8000"
    #     "--outputTransport"
    #     "sse"
    #     "--messagePath"
    #     "/message"
    #   ];
    #   extraOptions = [
    #     "--rm" # Remove container when it exits
    #   ];
    # };

    todoist-mcp = {
      image = "supercorp/supergateway";
      ports = [ "8001:8001" ];

      cmd = [
        "--stdio"
        "npx @abhiz123/todoist-mcp-server"
        # "npx -y @smithery/cli install @abhiz123/todoist-mcp-server"
        "--port"
        "8001"
        "--outputTransport"
        "sse"
        "--messagePath"
        "/message"
        "--logLevel debug"
      ];

      environment = {
        TODOIST_API_TOKEN = "";
      };
      extraOptions = [
        "--rm" # Remove container when it exits
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 5678 8000 ];
}


