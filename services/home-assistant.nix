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
        # The File integration appends the Tado-vs-phones presence log here.
        allowlist_external_dirs = [ "/data/.state/home-assistant/logs" ];
      };
      # http: is no longer read from YAML (HA 2026.x migrated it into
      # .storage/http). Reverse-proxy settings for Caddy (trust 127.0.0.1/::1,
      # use X-Forwarded-For) and the ban threshold live there now: Settings >
      # System > Network.
      lovelace.resource_mode = "yaml";

      # Octopus re-plans the car's charging slots about every 30 minutes, so
      # "what was planned" has to be pinned to a moment: 21:00 each night, and
      # whenever a plan appears after there was none (car plugged in). The
      # Car page compares this frozen plan with what actually charged.
      template = [
        {
          trigger = [
            { trigger = "time"; at = "21:00:00"; }
            { trigger = "homeassistant"; event = "start"; }
            {
              trigger = "state";
              entity_id = "binary_sensor.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_dispatching";
              attribute = "planned_dispatches";
            }
          ];
          condition = [{
            condition = "template";
            value_template = "{{ trigger.platform == 'time' or (trigger.platform == 'homeassistant' and states('sensor.car_charging_plan_snapshot') in ['unknown', 'unavailable']) or (trigger.platform == 'state' and (trigger.from_state.attributes.planned_dispatches or []) | count == 0 and (trigger.to_state.attributes.planned_dispatches or []) | count > 0) }}";
          }];
          sensor = [{
            name = "Car charging plan snapshot";
            unique_id = "car_charging_plan_snapshot";
            icon = "mdi:calendar-clock";
            device_class = "timestamp";
            state = "{{ now().isoformat() }}";
            # plain ISO strings, so the dashboard can read the list
            attributes.planned = "{% set ns = namespace(out=[]) %}{% for x in state_attr('binary_sensor.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_dispatching', 'planned_dispatches') or [] %}{% set ns.out = ns.out + [{'start': as_datetime(x.start | string).isoformat(), 'end': as_datetime(x.end | string).isoformat(), 'kwh': (x.charge_in_kwh | float(0)) | abs | round(2)}] %}{% endfor %}{{ ns.out }}";
          }];
        }
      ];
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
      # Tado cloud, only for Tado's own Home/Away (thermostats are on HomeKit).
      # Polling is switched off in HA; an automation asks twice a night to
      # stay inside Tado's daily API allowance.
      "tado"
      "file"
    ];

    # Pinned by nixpkgs rather than HACS: the hand-installed 13.x broke when
    # Octopus changed its API (rate sensors stopped setting up).
    customComponents = with pkgs.home-assistant-custom-components; [
      octopus_energy
    ];


    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      mini-graph-card
      # Downstairs heating chart: temperature with gas/underfloor bands
      apexcharts-card
    ];
  };

  # Writable folder for the Tado-vs-phones presence log
  # (allowlisted via homeassistant.allowlist_external_dirs above).
  systemd.tmpfiles.rules = [
    "d /data/.state/home-assistant/logs 0750 hass hass -"
  ];
}
