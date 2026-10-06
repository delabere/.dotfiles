{ config, lib, pkgs, ... }:

# Self-hosted Vellum assistants (https://github.com/vellum-ai/vellum-assistant).
#
# Mirrors what `vellum hatch --docker` does (cli/src/lib/statefulset.ts): each
# instance is three containers sharing the assistant's network namespace —
# assistant (daemon), gateway (the only thing clients talk to) and
# credential-executor — plus a Caddy "edge" in the same namespace standing in
# for the nginx edge `vellum tunnel` runs (cli/src/lib/nginx-ingress.ts): it
# serves the web app and is what the gateway trusts as its proxy, because it
# connects from loopback. Only the edge is published, on localhost, and the
# host Caddy fronts it with TLS. Pair a phone with `sudo vellum-pair <instance>`.
#
# `vellum hatch` also stores the model API key and creates the
# `<provider>-personal` connection the default profiles use; ANTHROPIC_API_KEY
# in the environment is NOT picked up afterwards. For a new instance, once:
#   docker exec vellum-<name>-assistant assistant inference providers create \
#     anthropic-personal --provider anthropic --credential credential/anthropic/api_key
#   docker exec -it vellum-<name>-assistant assistant credentials prompt \
#     --service anthropic --field api_key   # asks for the key in the paired app
# Both live in the workspace volume, so they survive restarts and upgrades.
# Or run on Vellum credits instead: `sudo vellum-link <name>`.
#
# The web app served from the edge runs in "remote-gateway" mode, which blocks
# every call to the Vellum platform (Vellum's own edge does the same), so the
# app's "connect Google" style buttons fail. Connect OAuth providers from the
# host instead; managed mode goes through Vellum's OAuth app once linked:
#   sudo docker exec -it vellum-<name>-assistant assistant oauth connect google --no-browser

let
  cfg = config.services.vellum;
  docker = "${config.virtualisation.docker.package}/bin/docker";

  # Fixed by the images (packages/local-mode DEFAULT_PORTS).
  assistantPort = 7821;
  gatewayPort = 7830;
  edgePort = 7840;
  edgeImage = "caddy:2.11.4-alpine";

  instanceOpts = { name, ... }: {
    options = {
      domain = lib.mkOption {
        type = lib.types.str;
        description = "Public hostname Caddy serves this assistant on.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Host port (bound to 127.0.0.1) the edge is published on.";
      };
      version = lib.mkOption {
        type = lib.types.str;
        default = cfg.version;
        description = "Image tag for all three containers.";
      };
      memory = lib.mkOption {
        type = lib.types.str;
        default = "3g";
        description = "Memory cap for the assistant container.";
      };
      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Optional env file for the assistant, e.g. ANTHROPIC_API_KEY=... from
          agenix. Provider keys can also be set from the app instead.
        '';
      };
      extraEnvironment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Extra environment for the assistant container.";
      };
    };
  };

  # The web SPA (pair page, browser chat) that `vellum tunnel` serves from its
  # nginx edge at /assistant/. The gateway itself only speaks /v1.
  webDist = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@vellumai/web/-/web-${lib.removePrefix "v" cfg.version}.tgz";
    hash = cfg.webHash;
  };

  # Per-instance copy of the SPA with its runtime config baked into index.html,
  # as buildRemoteWebIndexHtml in cli/src/lib/nginx-ingress.ts does.
  mkWebRoot = name: icfg:
    let
      webConfig = builtins.toJSON {
        mode = "remote-gateway";
        apiBaseUrl = "/v1";
        platformDisabled = true;
        disablePlatform = true;
        assistantName = name;
        assistantId = name;
      };
      script = "<script>window.__VELLUM_CONFIG__=${
        builtins.replaceStrings [ "<" ">" ] [ "\\u003c" "\\u003e" ] webConfig
      }</script>";
    in
    pkgs.runCommand "vellum-web-${name}" { } ''
      cp -r ${webDist}/dist $out
      chmod u+w $out $out/index.html
      substituteInPlace $out/index.html --replace-fail '</head>' ${lib.escapeShellArg "${script}</head>"}
      cp ${pkgs.writeText "config.json" webConfig} $out/__config.json
    '';

  # Host-only gateway routes the edge must never expose (DENYLIST_LOCATIONS).
  deniedPaths = lib.concatMapStringsSep " " (p: "${p} ${p}/") [
    "/auth/token"
    "/v1/pair"
    "/v1/pair/web-init"
    "/v1/devices"
    "/v1/devices/revoke"
    "/v1/guardian/init"
    "/v1/guardian/reset-bootstrap"
    "/v1/remote-web/pairing-requests"
    "/v1/remote-web/pairing-requests/approve"
    "/v1/remote-web/pairing-requests/deny"
    "/v1/remote-web/pairing-verification"
  ] + " /assistant/__local/* /assistant/__gateway/* /assistant/__gateway-paired/*";

  # Mirrors the nginx edge's buildRemoteWebIngressLocations. The host Caddy
  # reaches it through Docker's port forwarding (a private-range peer), so its
  # X-Forwarded-For is trusted to give the real client address.
  mkEdgeCaddyfile = name: icfg: pkgs.writeText "vellum-${name}-edge.Caddyfile" ''
    {
      admin off
      auto_https off
      persist_config off
      servers {
        trusted_proxies static private_ranges
      }
    }

    http://:${toString edgePort} {
      @denied path ${deniedPaths}
      handle @denied {
        respond 404
      }

      @gateway path /healthz /readyz /v1/* /webhooks/*
      handle @gateway {
        reverse_proxy 127.0.0.1:${toString gatewayPort} {
          header_up X-Vellum-Edge-Forwarded 1
          header_up X-Vellum-Client-Ip {client_ip}
          flush_interval -1
        }
      }

      @root path / /assistant
      redir @root /assistant/ 302

      # Only the static SPA is compressed: the proxied API carries secrets
      # alongside attacker-influenced content (BREACH).
      handle_path /assistant/* {
        root * /srv
        @assets path /assets/*
        @shell not path /assets/* /__config
        header @assets Cache-Control "public, max-age=31536000, immutable"
        header @shell Cache-Control "no-cache"
        header /__config Cache-Control "no-store"
        rewrite /__config /__config.json
        try_files {path} /index.html
        encode gzip
        file_server
      }

      handle {
        respond 404
      }
    }
  '';

  mkInstance = name: icfg:
    let
      prefix = "vellum-${name}";
      net = "${prefix}-net";
      vol = v: "${prefix}-${v}";
      stateDir = "/var/lib/vellum/${name}";
      secretsFile = "${stateDir}/secrets.env";
      image = svc: "vellumai/vellum-${svc}:${icfg.version}";
      init = "${prefix}-init.service";
      assistantUnit = "docker-${prefix}-assistant.service";
      sidecar = {
        dependsOn = [ "${prefix}-assistant" ];
        extraOptions = [ "--init" "--network=container:${prefix}-assistant" ];
      };
    in
    {
      containers = {
        "${prefix}-assistant" = {
          image = image "assistant";
          environmentFiles = [ secretsFile ] ++ lib.optional (icfg.environmentFile != null) icfg.environmentFile;
          environment = {
            IS_CONTAINERIZED = "true";
            # Selects platform.vellum.ai (unset means dev-platform); the published
            # CLI forwards this from the host.
            VELLUM_ENVIRONMENT = "production";
            DEBUG_STDOUT_LOGS = "1";
            VELLUM_CLOUD = "docker";
            VELLUM_ASSISTANT_NAME = name;
            RUNTIME_HTTP_HOST = "0.0.0.0";
            RUNTIME_HTTP_PORT = toString assistantPort;
            GATEWAY_INTERNAL_URL = "http://localhost:${toString gatewayPort}";
            VELLUM_WORKSPACE_DIR = "/workspace";
            VELLUM_BACKUP_DIR = "/workspace/.backups";
            VELLUM_BACKUP_KEY_PATH = "/workspace/.backup.key";
            CES_CREDENTIAL_URL = "http://localhost:8090";
            CES_BOOTSTRAP_SOCKET_DIR = "/run/ces-bootstrap";
            GATEWAY_IPC_SOCKET_DIR = "/run/gateway-ipc";
            ASSISTANT_IPC_SOCKET_DIR = "/run/assistant-ipc";
            TZ = config.time.timeZone;
          } // icfg.extraEnvironment;
          ports = [ "127.0.0.1:${toString icfg.port}:${toString edgePort}" ];
          volumes = [
            "${vol "workspace"}:/workspace"
            "${vol "socket"}:/run/ces-bootstrap"
            "${vol "assistant-ipc"}:/run/assistant-ipc"
            "${vol "gateway-ipc"}:/run/gateway-ipc"
          ];
          extraOptions = [ "--init" "--network=${net}" "--memory=${icfg.memory}" ];
        };

        "${prefix}-gateway" = sidecar // {
          image = image "gateway";
          user = "0";
          environmentFiles = [ secretsFile ];
          environment = {
            VELLUM_ENVIRONMENT = "production";
            VELLUM_WORKSPACE_DIR = "/workspace";
            GATEWAY_SECURITY_DIR = "/gateway-security";
            ASSISTANT_HOST = "localhost";
            CES_CREDENTIAL_URL = "http://localhost:8090";
            GATEWAY_IPC_SOCKET_DIR = "/run/gateway-ipc";
            ASSISTANT_IPC_SOCKET_DIR = "/run/assistant-ipc";
            GATEWAY_PORT = toString gatewayPort;
            RUNTIME_HTTP_PORT = toString assistantPort;
          };
          volumes = [
            "${vol "workspace"}:/workspace"
            "${vol "gateway-sec"}:/gateway-security"
            "${vol "assistant-ipc"}:/run/assistant-ipc"
            "${vol "gateway-ipc"}:/run/gateway-ipc"
          ];
        };

        "${prefix}-credential-executor" = sidecar // {
          image = image "credential-executor";
          environmentFiles = [ secretsFile ];
          environment = {
            CES_MODE = "managed";
            VELLUM_WORKSPACE_DIR = "/workspace";
            CES_BOOTSTRAP_SOCKET_DIR = "/run/ces-bootstrap";
            CREDENTIAL_SECURITY_DIR = "/ces-security";
          };
          volumes = [
            "${vol "workspace"}:/workspace:ro"
            "${vol "socket"}:/run/ces-bootstrap"
            "${vol "ces-sec"}:/ces-security"
          ];
        };

        "${prefix}-edge" = sidecar // {
          image = edgeImage;
          volumes = [
            "${mkEdgeCaddyfile name icfg}:/etc/caddy/Caddyfile:ro"
            "${mkWebRoot name icfg}:/srv:ro"
          ];
          extraOptions = sidecar.extraOptions ++ [
            "--cap-drop=ALL"
            # The image's caddy binary carries this file capability; exec fails without it.
            "--cap-add=NET_BIND_SERVICE"
            "--security-opt=no-new-privileges:true"
          ];
        };
      };

      services = {
        # One-time secrets plus the per-instance network and volume ownership
        # that `vellum hatch` would otherwise set up.
        "${prefix}-init" = {
          description = "Prepare Vellum assistant '${name}'";
          after = [ "docker.service" ];
          requires = [ "docker.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            install -d -m 0700 ${stateDir}
            if [ ! -s ${secretsFile} ]; then
              umask 077
              gen() { ${pkgs.openssl}/bin/openssl rand -hex 32; }
              {
                echo "ACTOR_TOKEN_SIGNING_KEY=$(gen)"
                echo "CES_SERVICE_TOKEN=$(gen)"
                echo "GUARDIAN_BOOTSTRAP_SECRET=$(gen)"
              } > ${secretsFile}
            fi
            ${docker} network inspect ${net} >/dev/null 2>&1 || ${docker} network create ${net}
            # The daemon runs as UID 1001 and needs to own these.
            ${docker} run --rm --user 0 --entrypoint chown \
              -v ${vol "workspace"}:/workspace \
              -v ${vol "assistant-ipc"}:/run/assistant-ipc \
              -v ${vol "gateway-ipc"}:/run/gateway-ipc \
              ${image "assistant"} 1001:1001 /workspace /run/assistant-ipc /run/gateway-ipc
          '';
        };

        "docker-${prefix}-assistant" = {
          after = [ init ];
          requires = [ init ];
        };

        # Workspace config `vellum tunnel` would set: the public address used
        # for OAuth callbacks and webhooks. Reapplied on every start.
        "${prefix}-configure" = {
          description = "Configure Vellum assistant '${name}'";
          after = [ assistantUnit ];
          bindsTo = [ assistantUnit ];
          wantedBy = [ assistantUnit ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            for _ in $(seq 60); do
              if ${docker} exec ${prefix}-assistant assistant config set \
                  ingress.publicBaseUrl https://${icfg.domain}; then
                exit 0
              fi
              sleep 5
            done
            echo "assistant never became ready" >&2
            exit 1
          '';
        };
        # Sidecars live in the assistant's network namespace, so they must
        # restart whenever it does.
        "docker-${prefix}-gateway" = {
          bindsTo = [ assistantUnit ];
          partOf = [ assistantUnit ];
        };
        "docker-${prefix}-credential-executor" = {
          bindsTo = [ assistantUnit ];
          partOf = [ assistantUnit ];
        };
        "docker-${prefix}-edge" = {
          bindsTo = [ assistantUnit ];
          partOf = [ assistantUnit ];
        };
      };

      caddy."${icfg.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString icfg.port} {
          flush_interval -1
        }
      '';
    };

  built = lib.mapAttrs mkInstance cfg.instances;
  collect = attr: lib.mkMerge (lib.mapAttrsToList (_: b: b.${attr}) built);

  # Mint a pairing challenge on the gateway over loopback (from inside the
  # assistant's netns, which is the local-presence proof) and approve it.
  # Mirrors `vellum pair --app`.
  domains = lib.mapAttrs (_: i: i.domain) cfg.instances;
  vellumPair = pkgs.writeShellApplication {
    name = "vellum-pair";
    runtimeInputs = [ config.virtualisation.docker.package pkgs.jq pkgs.qrencode ];
    text = ''
      declare -A domains=(${lib.concatStrings (lib.mapAttrsToList (n: d: "[${n}]=${d} ") domains)})
      export DOCKER_HOST=unix:///run/docker.sock
      name="''${1:-}"
      if [ -z "$name" ] || [ -z "''${domains[$name]:-}" ]; then
        echo "usage: vellum-pair <${lib.concatStringsSep "|" (lib.attrNames domains)}> [label]" >&2
        echo "       vellum-pair <instance> --approve ABCD-EFGH" >&2
        exit 1
      fi
      base="https://''${domains[$name]}"
      gw() { docker exec -i "vellum-$name-assistant" curl -fsS -X POST -H 'Content-Type: application/json' \
               --data-binary @- "http://localhost:${toString gatewayPort}$1"; }

      if [ "''${2:-}" = "--approve" ]; then
        jq -n --arg c "$3" '{userCode: $c}' | gw /v1/remote-web/pairing-verification | jq .
        exit 0
      fi

      label="''${2:-$name}"
      challenge=$(jq -n --arg u "$base" '{publicBaseUrl: $u}' | gw /v1/remote-web/pairing-challenge)
      jq '{userCode: .userCode}' <<<"$challenge" | gw /v1/remote-web/pairing-verification >/dev/null
      appUrl=$(jq -r --arg u "$base" --arg n "$label" \
        '"vellum-assistant://connect?url=\($u|@uri)&code=\(.deviceCode|@uri)&name=\($n|@uri)"' <<<"$challenge")
      qrencode -t ansiutf8 "$appUrl"
      echo "App link:  $appUrl"
      echo "Web link:  $(jq -r .verificationUri <<<"$challenge")"
      echo "Expires:   $(jq -r .expiresAt <<<"$challenge")"
    '';
  };

  # Link an instance to a Vellum Platform account so it runs on Vellum credits.
  vellumLink = pkgs.writeShellApplication {
    name = "vellum-link";
    runtimeInputs = with pkgs; [ config.virtualisation.docker.package jq curl openssl coreutils gnused ];
    text = ''
      declare -A domains=(${lib.concatStrings (lib.mapAttrsToList (n: d: "[${n}]=${d} ") domains)})
      VELLUM_VERSION=${cfg.version}
    '' + builtins.readFile ./vellum-link.sh;
  };
in
{
  # Upgrading Vellum: bump `version` and `webHash` together.
  #   1. Pick a tag that exists for all three images (they release in
  #      lockstep, and the web app is published to npm under the same version):
  #        curl -s 'https://hub.docker.com/v2/repositories/vellumai/vellum-assistant/tags?page_size=5&ordering=last_updated' | jq -r '.results[].name'
  #   2. Hash the matching web app (version without the leading "v"):
  #        v=0.12.6; nix hash convert --hash-algo sha256 --to sri \
  #          "$(nix-prefetch-url --unpack "https://registry.npmjs.org/@vellumai/web/-/web-$v.tgz")"
  #      (or set webHash = lib.fakeHash, rebuild, and copy the "got:" hash).
  #   3. Rebuild. Assistants migrate their own data on start; check
  #      `journalctl -u docker-vellum-<name>-assistant` and `/readyz`.
  #      If the edge misbehaves after an upgrade, diff DENYLIST_LOCATIONS and
  #      buildRemoteWebIngressLocations in cli/src/lib/nginx-ingress.ts
  #      upstream against mkEdgeCaddyfile / deniedPaths here.
  # A per-instance `version` override only changes that instance's images; the
  # web app always follows the top-level `version`.
  options.services.vellum = {
    version = lib.mkOption {
      type = lib.types.str;
      default = "v0.12.6";
      description = "Default image tag (see hub.docker.com/r/vellumai/vellum-assistant/tags).";
    };
    webHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-4a5t5d2LKe0OJbwzN6w1TCSpcifSkFN85oe05JIUCoA=";
      description = "Hash of the @vellumai/web tarball matching `version`; bump alongside it.";
    };
    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceOpts);
      default = { };
    };
  };

  config = lib.mkIf (cfg.instances != { }) {
    virtualisation.oci-containers.containers = collect "containers";
    systemd.services = collect "services";
    services.caddy.virtualHosts = collect "caddy";
    environment.systemPackages = [ vellumPair vellumLink ];
  };
}
