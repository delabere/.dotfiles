{ config, ... }: {
  age.secrets = {
    homepage-env = {
      file = ./../secrets/homepage-env.age;
      owner = "root";
      group = "users";
      mode = "400";
    };
  };

  services.homepage-dashboard = {
    allowedHosts = "*";
    enable = true;
    environmentFile = config.age.secrets.homepage-env.path;
    bookmarks = [{
      dev = [
        {
          github = [{
            abbr = "GH";
            href = "https://github.com/delabere/.dotfiles";
            icon = "github-light.png";
          }];
        }
        {
          "homepage docs" = [{
            abbr = "HD";
            href = "https://gethomepage.dev";
            icon = "homepage.png";
          }];
        }
      ];
    }];
    services = [
      {
        media = [
          {
            Plex = {
              icon = "plex.png";
              href = "http://brain:32400";
              description = "media management";
              # widget = {
              #   type = "plex";
              #   url = "http://brain:32400";
              # key = "{{HOMEPAGE_VAR_PLEX_API_KEY}}";
              # };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "http://brain:7878";
              description = "film management";
              widget = {
                type = "radarr";
                url = "http://brain.:7878";
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "http://brain:8989";
              description = "tv management";
              widget = {
                type = "sonarr";
                url = "http://brain:8989";
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "http://brain:9696";
              description = "index management";
              widget = {
                type = "prowlarr";
                url = "http://brain:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
              };
            };
          }
          {
            Transmission = {
              icon = "transmission.png";
              href = "http://192.168.1.11:9091";
              description = "torrents";
              widget = {
                type = "transmission";
                url = "http://192.168.1.11:9091";
              };
            };
          }
          {
            HomeAssistant = {
              icon = "home-assistant.png";
              href = "http://brain:8123";
              description = "Home Assistant";
              widget = {
                type = "homeassistant";
                url = "http://brain:8123";
                key = "{{HOMEPAGE_VAR_HOMEASSISTANT_API_KEY}}";
                custom = [
                  { state = "sensor.speedtest_download"; }
                  { state = "sensor.speedtest_upload"; }
                  { state = "sensor.downstairs_heating"; label = "downstairs heating"; }
                  { template = "{{ states.switch|selectattr('state','equalto','on')|list|length }}"; label = "switches on"; }
                  { state = "weather.forecast_home"; label = "wind speed"; value = "{attributes.wind_speed} {attributes.wind_speed_unit}"; }
                ];
              };
            };
          }
          {
            Grafana = {
              icon = "grafana.png";
              # node exporter dash
              href = "http://brain:3000";
              description = "system dashboard";
              widget = {
                type = "grafana";
                url = "http://brain:3000";
                username = "admin";
                password = "admin";
              };
            };
          }
          {
            Btop = {
              icon = "terminal.png";
              href = "http://brain:7681";
              description = "btop";
            };
          }
        ];
      }
    ];
    settings = {
      title = "ranger's dashboard";
      favicon = "https://jnsgr.uk/favicon.ico";
      headerStyle = "clean";
      layout = {
        media = { style = "row"; columns = 3; };
      };
    };
    widgets = [
      { search = { provider = "google"; target = "_blank"; }; }
      { resources = { label = "system"; cpu = true; memory = true; }; }
      { resources = { label = "internal storage"; disk = [ "/" ]; }; }
      { resources = { label = "external storage"; disk = [ "/mnt/bigboi" ]; }; }
      { resources = { label = "external 2"; disk = [ "/mnt/external" ]; }; }
      {
        openmeteo = {
          label = "London";
          timezone = "Europe/London";
          latitude = "51.4934";
          longitude = "0.0098";
          units = "metric";
        };
      }
    ];
  };
}
