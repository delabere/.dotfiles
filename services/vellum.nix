{ config, lib, pkgs, ... }:

# Self-hosted Vellum assistants (https://github.com/vellum-ai/vellum-assistant).
#
# Mirrors what `vellum hatch --docker` does (cli/src/lib/statefulset.ts): each
# instance is three containers sharing the assistant's network namespace —
# assistant (daemon), gateway (the only thing clients talk to) and
# credential-executor. Only the gateway is published, on localhost, and Caddy
# fronts it. Pair a phone with `sudo vellum-pair <instance>`.

let
  cfg = config.services.vellum;
  docker = "${config.virtualisation.docker.package}/bin/docker";

  # Fixed by the images (packages/local-mode DEFAULT_PORTS).
  assistantPort = 7821;
  gatewayPort = 7830;

  instanceOpts = { name, ... }: {
    options = {
      domain = lib.mkOption {
        type = lib.types.str;
        description = "Public hostname Caddy serves this assistant's gateway on.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Host port (bound to 127.0.0.1) the gateway is published on.";
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
          ports = [ "127.0.0.1:${toString icfg.port}:${toString gatewayPort}" ];
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
      };

      caddy."${icfg.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString icfg.port}
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
in
{
  options.services.vellum = {
    version = lib.mkOption {
      type = lib.types.str;
      default = "v0.12.5";
      description = "Default image tag (see hub.docker.com/r/vellumai/vellum-assistant/tags).";
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
    environment.systemPackages = [ vellumPair ];
  };
}
