{ config, pkgs, ... }: {

  services.home-assistant = {
    enable = true;

    configDir = "/data/.state/home-assistant/";
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      lovelace.resource_mode = "yaml";
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
    extraComponents = [
      "shelly"
      "tuya"
      "tado"
      "ecovacs"
      "speedtestdotnet"
      "met"
      "tesla_fleet"
      "bthome"
      "homekit_controller"
      "androidtv_remote"
      "radio_browser"
      "cast"
    ];

    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      mini-graph-card
    ];
  };
}
