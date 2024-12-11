{ config, ... }: {
  age.secrets = {
    "homepage-env" = {
      file = ./../secrets/homepage-env.age;
      owner = "root";
      group = "users";
      mode = "400";
    };
  };

  # age.secrets = {
  #   "tailscale-authkey" = {
  #     # change to whatever path it is in your NixOS configuration
  #     file = ./../secrets/tailscale-authkey.age;
  #   };
  # };
  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.age.secrets."homepage-env".path;
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
    # machines = [ ];
    #   machines = [
    #     {
    #       tower = [{
    #         abbr = "TR";
    #         href = "https://dash.crgrd.uk";
    #         icon = "homarr.png";
    #       }];
    #     }
    #     {
    #       gbox = [{
    #         abbr = "GB";
    #         href = "https://dash.gbox.crgrd.uk";
    #         icon = "homepage.png";
    #       }];
    #     }
    #   ];
    # }];
    services = [
      {
        media = [
          {
            Plex = {
              icon = "plex.png";
              href = "http://brain.degu-vega.ts.net:32400";
              description = "media management";
              # widget = {
              #   type = "plex";
              #   url = "http://brain.degu-vega.ts.net:32400";
              # key = "{{HOMEPAGE_VAR_PLEX_API_KEY}}";
              # };
            };
          }
          {
            Radarr = {
              icon = "radarr.png";
              href = "http://brain.degu-vega.ts.net:7878";
              description = "film management";
              widget = {
                type = "radarr";
                url = "http://brain.degu-vega.ts.net:7878";
                key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr.png";
              href = "http://brain.degu-vega.ts.net:8989";
              description = "tv management";
              widget = {
                type = "sonarr";
                url = "http://brain.degu-vega.ts.net:8989";
                key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.png";
              href = "http://brain.degu-vega.ts.net:9696";
              description = "index management";
              widget = {
                type = "prowlarr";
                url = "http://brain.degu-vega.ts.net:9696";
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
              href = "http://brain.degu-vega.ts.net:8123";
              description = "Home Assistant";
              widget = {
                type = "homeassistant";
                url = "http://brain.degu-vega.ts.net:8123";
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

        ];
      }
      # {
      #   infra = [
      #     {
      #       Files = {
      #         description = "file manager";
      #         icon = "files.png";
      #         href = "https://files.jnsgr.uk";
      #       };
      #     }
      #     {
      #       "Syncthing (thor)" = {
      #         description = "syncthing ui for thor";
      #         icon = "syncthing.png";
      #         href = "https://thor.sync.jnsgr.uk";
      #       };
      #     }
      #     {
      #       "Syncthing (kara)" = {
      #         description = "syncthing ui for kara";
      #         icon = "syncthing.png";
      #         href = "https://kara.sync.jnsgr.uk";
      #       };
      #     }
      #     {
      #       "Syncthing (freyja)" = {
      #         description = "syncthing ui for freyja";
      #         icon = "syncthing.png";
      #         href = "https://freyja.sync.jnsgr.uk";
      #       };
      #     }
      #   ];
      # }
      # {
      #   machines = [
      #     {
      #       thor = {
      #         description = "thor";
      #         icon = "tailscale.png";
      #         href = "https://dash.jnsgr.uk";
      #         widget = {
      #           type = "tailscale";
      #           deviceid = "{{HOMEPAGE_VAR_TAILSCALE_THOR_DEVICE_ID}}";
      #           key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
      #         };
      #       };
      #     }
      #     {
      #       tower = {
      #         description = "tower";
      #         icon = "tailscale.png";
      #         href = "https://dash.crgrd.uk";
      #         widget = {
      #           type = "tailscale";
      #           deviceid = "{{HOMEPAGE_VAR_TAILSCALE_TOWER_DEVICE_ID}}";
      #           key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
      #         };
      #       };
      #     }
      #     {
      #       gbox = {
      #         description = "gbox";
      #         icon = "tailscale.png";
      #         href = "https://dash.gbox.crgrd.uk";
      #         widget = {
      #           type = "tailscale";
      #           deviceid = "{{HOMEPAGE_VAR_TAILSCALE_GBOX_DEVICE_ID}}";
      #           key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
      #         };
      #       };
      #     }
      #     {
      #       hugin = {
      #         description = "hugin";
      #         icon = "tailscale.png";
      #         href = "https://dash.jnsgr.uk";
      #         widget = {
      #           type = "tailscale";
      #           deviceid = "{{HOMEPAGE_VAR_TAILSCALE_HUGIN_DEVICE_ID}}";
      #           key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
      #         };
      #       };
      #     }
      #   ];
      # }
    ];
    settings = {
      title = "ranger's dashboard";
      favicon = "https://jnsgr.uk/favicon.ico";
      headerStyle = "clean";
      layout = {
        media = { style = "row"; columns = 3; };
        # infra = { style = "row"; columns = 4; };
        # machines = { style = "row"; columns = 4; };
      };
    };
    widgets = [
      { search = { provider = "google"; target = "_blank"; }; }
      { resources = { label = "system"; cpu = true; memory = true; }; }
      { resources = { label = "internal storage"; disk = [ "/data" ]; }; }
      { resources = { label = "external storage"; disk = [ "/mnt/external" ]; }; }
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
