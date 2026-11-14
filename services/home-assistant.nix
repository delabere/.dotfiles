{ config, pkgs, ... }:
let
  houseCalc = builtins.readFile ./home-assistant/house-car-slot-saving.calc.jinja;
  ufhCalc = builtins.readFile ./home-assistant/ufh-preheat-saving.calc.jinja;
  prevOr0 = "(this.state | float(0) if this.state not in ['unknown', 'unavailable'] else 0)";
in
{

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
      lovelace = {
        resource_mode = "yaml";
        dashboards.dashboard-lights = {
          mode = "yaml";
          title = "Main";
          icon = "mdi:home";
          show_in_sidebar = true;
          require_admin = false;
          filename = "nix/dashboards/main.yaml";
        };
      };

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
        {
          # Ready-by forecast shared by the Car page and the hard-deadline override
          trigger = [
            { trigger = "time_pattern"; minutes = "/5"; }
            { trigger = "homeassistant"; event = "start"; }
            {
              trigger = "state";
              entity_id = [
                "sensor.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_state_of_charge"
                "sensor.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_charge_cap_hours"
                "binary_sensor.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_dispatching"
                "number.octopus_energy_00000000_0002_4000_8020_000000076b06_intelligent_charge_target"
                "input_boolean.smart_car_charge"
                "input_boolean.car_must_be_ready"
                "input_datetime.car_must_be_ready_by"
              ];
            }
          ];
          sensor = [{
            name = "Car charge forecast";
            unique_id = "car_charge_forecast";
            icon = "mdi:battery-clock";
            device_class = "timestamp";
            state = "{{ now().isoformat() }}";
            attributes.forecast = builtins.readFile ./home-assistant/car-charge-forecast.jinja;
          }];
        }
        {
          # Saving vs peak for underfloor heating used in the nightly cheap window
          trigger = [
            { trigger = "state"; entity_id = "sensor.shellyplus1pm_e465b8930098_switch_0_energy"; }
            { trigger = "homeassistant"; event = "start"; }
          ];
          sensor = [{
            name = "Underfloor pre-heat saving";
            unique_id = "underfloor_preheat_saving";
            icon = "mdi:heating-coil";
            unit_of_measurement = "GBP";
            device_class = "monetary";
            state_class = "total";
            state = ufhCalc + "{{ (${prevOr0} + u.saving) | round(4) }}";
            attributes.kwh = ufhCalc + "{{ ((this.attributes.kwh | default(0) | float(0)) + u.kwh) | round(3) }}";
          }];
        }
        {
          # Saving vs peak for the rest of the house in half-hours made cheap by car charging (a day late)
          trigger = [
            { trigger = "state"; entity_id = "sensor.octopus_energy_electricity_23j0307021_1200041244369_previous_accumulative_cost"; }
            { trigger = "homeassistant"; event = "start"; }
          ];
          sensor = [{
            name = "House saving in car-charging slots";
            unique_id = "house_saving_car_slots";
            icon = "mdi:home-lightning-bolt";
            unit_of_measurement = "GBP";
            device_class = "monetary";
            state_class = "total";
            state = houseCalc + "{{ (${prevOr0} + (r.saving if r.day is not none and r.day != this.attributes.last_day | default('') else 0)) | round(4) }}";
            attributes.last_day = houseCalc + "{{ r.day }}";
            attributes.last_day_saving = houseCalc + "{{ r.saving | round(2) }}";
            attributes.last_day_kwh = houseCalc + "{{ r.kwh | round(2) }}";
            attributes.last_day_slots = houseCalc + "{{ r.slots }}";
          }];
        }
        {
          # Hourly internet speed test (never at start-up). Fire event "speedtest_run" to test now.
          trigger = [
            { trigger = "time_pattern"; minutes = 17; }
            { trigger = "event"; event_type = "speedtest_run"; }
          ];
          action = [
            { action = "shell_command.speedtest"; response_variable = "r"; }
            { variables.ok = "{{ r.returncode == 0 and (r.stdout | default('')) | regex_match('^\\s*\\{') }}"; }
            { variables.res = "{{ (r.stdout | from_json) if ok else {} }}"; }
          ];
          sensor = [
            {
              name = "SpeedTest Download";
              unique_id = "ookla_speedtest_download";
              unit_of_measurement = "Mbit/s";
              device_class = "data_rate";
              state_class = "measurement";
              icon = "mdi:download";
              state = "{{ (res.download.bandwidth * 8 / 1000000) | round(2) if ok else this.state }}";
              attributes.server = "{{ (res.server.name ~ ', ' ~ res.server.location) if ok else this.attributes.server | default(none) }}";
              attributes.isp = "{{ res.isp if ok else this.attributes.isp | default(none) }}";
              attributes.result_url = "{{ res.result.url if ok else this.attributes.result_url | default(none) }}";
              attributes.last_error = "{{ none if ok else (r.stderr | default('') | truncate(200)) }}";
            }
            {
              name = "SpeedTest Upload";
              unique_id = "ookla_speedtest_upload";
              unit_of_measurement = "Mbit/s";
              device_class = "data_rate";
              state_class = "measurement";
              icon = "mdi:upload";
              state = "{{ (res.upload.bandwidth * 8 / 1000000) | round(2) if ok else this.state }}";
            }
            {
              name = "SpeedTest Ping";
              unique_id = "ookla_speedtest_ping";
              unit_of_measurement = "ms";
              device_class = "duration";
              state_class = "measurement";
              icon = "mdi:timer-outline";
              state = "{{ res.ping.latency | round(1) if ok else this.state }}";
            }
          ];
        }
      ];
      utility_meter = {
        underfloor_pre_heat_saving_month = { source = "sensor.underfloor_pre_heat_saving"; cycle = "monthly"; };
        house_car_slot_saving_month = { source = "sensor.house_saving_in_car_charging_slots"; cycle = "monthly"; };
      };
      # Config as code: services/home-assistant/config is linked into HA's config dir as nix/
      # (see systemd.tmpfiles below). The plain automations.yaml / scenes.yaml stay loaded as a
      # "UI area" for things made in the app, which can be moved into the repo later.
      "automation nix" = "!include nix/automations.yaml";
      "automation ui" = "!include automations.yaml";
      "scene nix" = "!include nix/scenes.yaml";
      "scene ui" = "!include scenes.yaml";
      script = "!include scripts.yaml";
      input_boolean = "!include nix/input_boolean.yaml";
      input_text = "!include nix/input_text.yaml";
      input_datetime = "!include nix/input_datetime.yaml";
      "template helpers" = "!include nix/templates.yaml";
      # Ookla's official CLI. HA's speedtestdotnet integration (speedtest-cli) read under half the
      # real speed (113 vs 273 Mbit/s side by side) and also tested at every HA start-up.
      shell_command.speedtest = "${pkgs.ookla-speedtest}/bin/speedtest --accept-license --accept-gdpr --format=json";
    };
    extraComponents = [
      "shelly"
      "tuya"
      "ecovacs"
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

  # Restart HA whenever the repo-managed config (automations, helpers, dashboards…) changes,
  # so a deploy always leaves the running system matching the repo.
  systemd.services.home-assistant.restartTriggers = [ ./home-assistant/config ];

  # Writable folder for the Tado-vs-phones presence log
  # (allowlisted via homeassistant.allowlist_external_dirs above).
  systemd.tmpfiles.rules = [
    "d /data/.state/home-assistant/logs 0750 hass hass -"
    # repo-managed HA config (automations, scenes, helpers, templates, dashboards)
    "L+ /data/.state/home-assistant/nix - - - - ${./home-assistant/config}"
  ];
}
