{ config, pkgs, ... }: {

  services.home-assistant = {
    enable = true;

    configDir = "/data/.state/home-assistant/";
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      lovelace.mode = "storage";
    };
    extraComponents = [
      "shelly"
      "tuya"
      "tado"
      "ecovacs"
      "speedtestdotnet"
      "met"
      "tesla_fleet"
    ];

    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      mini-graph-card
    ];
  };
}
