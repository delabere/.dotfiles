{ config, pkgs, ... }: {

  services.home-assistant = {
    enable = true;

    configDir = "/data/.state/home-assistant/";
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      api = { };
      homeassistant = {
        external_url = "https://ha.delabere.com";
        internal_url = "http://brain:8123";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };
      lovelace.resource_mode = "yaml";
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
    extraComponents = [
      "shelly"
      "tuya"
      "ecovacs"
      "speedtestdotnet"
      "met"
      "tesla_fleet"
      "bthome"
      "homekit_controller"
      "androidtv_remote"
      "radio_browser"
      "cast"
      "samsungtv"
      "dlna_dmr"
    ];

    # Pinned by nixpkgs rather than HACS: the hand-installed 13.x broke when
    # Octopus changed its API (rate sensors stopped setting up).
    customComponents = with pkgs.home-assistant-custom-components; [
      octopus_energy
    ];

    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      mini-graph-card
    ];
  };
}
