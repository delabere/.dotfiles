{ config, pkgs, ... }: {


  age.secrets = {
    tailscale-authkey = {
      file = ./../secrets/tailscale-authkey.age;
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.age.secrets.tailscale-authkey.path;
    extraUpFlags = [
      "--advertise-routes=10.0.0.0/8"
      # "--advertise-exit-node"
      # "--accept-routes"
    ];
    # useRoutingFeatures = "both";
  };

  # # create a oneshot job to authenticate to Tailscale
  # systemd.services.tailscale-autoconnect = {
  #   description = "Automatic connection to Tailscale";
  #
  #   # make sure tailscale is running before trying to connect to tailscale
  #   after = [ "network-pre.target" "tailscale.service" ];
  #   wants = [ "network-pre.target" "tailscale.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #
  #   # set this service as a oneshot job
  #   serviceConfig.Type = "oneshot";
  #
  #   # have the job run this shell script
  #   script = with pkgs; ''
  #     # wait for tailscaled to settle
  #     sleep 2
  #
  #     # check if we are already authenticated to tailscale
  #     status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
  #     if [ $status = "Running" ]; then # if so, then do nothing
  #       exit 0
  #     fi
  #
  #     # otherwise authenticate with tailscale
  #     ${tailscale}/bin/tailscale up -authkey ${config.age.secrets."tailscale-authkey".path}
  #   '';
  # };

  # ...
  # networking.firewall = {
  #   # enable the firewall
  #   enable = true;
  #
  #   # always allow traffic from your Tailscale network
  #   trustedInterfaces = [ "tailscale0" ];
  #
  #   # allow the Tailscale UDP port through the firewall
  #   allowedUDPPorts = [ config.services.tailscale.port ];
  #
  #   # let you SSH in over the public internet
  #   allowedTCPPorts = [ 22 ];
  # };



  # environment.persistence."/nix/persist" = {
  #   directories = [
  #     "/var/lib/tailscale"
  #   ];
  # };
}
