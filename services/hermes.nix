{ config, lib, pkgs, ... }:

# Hermes Agent (https://github.com/NousResearch/hermes-agent), on trial as the
# Telegram assistant alongside Vellum. The module comes from the hermes-agent
# flake input (pinned to a release tag in flake.nix: Nix support upstream is
# "best effort", so upgrade by bumping the tag deliberately).
#
# Runs as the `hermes` system user (no sudo, not in the docker group). All
# state lives in /var/lib/hermes: .hermes/ holds config.yaml (generated from
# `settings` below, deep-merged so runtime `hermes config set` changes to other
# keys survive), .env (rebuilt from the agenix secret on every activation),
# state.db (sessions), memories/, skills/, cron/ and OAuth tokens.
#
# Secrets (secrets/hermes-env.age, edit with `agenix -e hermes-env.age` from
# secrets/):
#   OPENROUTER_API_KEY=...
#   TELEGRAM_BOT_TOKEN=...
#   TELEGRAM_ALLOWED_USERS=<your numeric Telegram user id>
#
# Telegram uses long polling, so no domain, Caddy vhost or open port is needed.
#
# CLI on brain (shares state with the service):
#   sudo -u hermes hermes ...        e.g. `hermes mcp login notion`
#   journalctl -u hermes-agent -f

let
  # `python`/`python3` pointing at the venv the hermes package runs on.
  hermesPython = pkgs.runCommand "hermes-python" { } ''
    venv=$(grep -oE '/nix/store/[a-z0-9]+-hermes-agent-env' \
      ${config.services.hermes-agent.package}/bin/hermes | head -1)
    [ -x "$venv/bin/python3" ] || { echo "hermes venv not found" >&2; exit 1; }
    mkdir -p $out/bin
    ln -s "$venv/bin/python3" $out/bin/python3
    ln -s "$venv/bin/python3" $out/bin/python
  '';

  # Outlook/Hotmail via Microsoft Graph (Softeria ms-365-mcp-server, pinned;
  # npx caches it under the hermes user's ~/.npm). Personal-account mode,
  # `consumers` authority (refresh tokens from `common` stop working), token
  # cache as files under /var/lib/hermes/ms365 (backed up). One-time login:
  #   sudo -u hermes -E ms365-mcp --login     (device code at microsoft.com/devicelogin)
  ms365Mcp = pkgs.writeShellScriptBin "ms365-mcp" ''
    export MS365_MCP_TENANT_ID=consumers
    export MS365_MCP_USE_KEYTAR=0
    export MS365_MCP_TOKEN_CACHE_PATH=/var/lib/hermes/ms365/token-cache.json
    export MS365_MCP_SELECTED_ACCOUNT_PATH=/var/lib/hermes/ms365/selected-account.json
    export PATH=${pkgs.nodejs}/bin:$PATH
    exec npx -y @softeria/ms-365-mcp-server@0.193.0 --preset outlook --read-only "$@"
  '';
in
{
  systemd.tmpfiles.rules = [ "d /var/lib/hermes/ms365 0700 hermes hermes -" ];

  age.secrets.hermes-env = {
    file = ./../secrets/hermes-env.age;
    owner = config.services.hermes-agent.user;
  };

  # Bundled skills are copied out of the Nix store read-only, so the agent's
  # self-improvement (skill_manage patching a bundled skill) fails with EACCES.
  # Make the copies writable before each start; personal/ (root-owned, from
  # hermesHomeFiles) stays read-only on purpose.
  systemd.services.hermes-skills-writable = {
    description = "Make Hermes's bundled skill copies writable";
    before = [ "hermes-agent.service" ];
    requiredBy = [ "hermes-agent.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      d=/var/lib/hermes/.hermes/skills
      [ -d "$d" ] || exit 0
      find "$d" -mindepth 1 -path "$d/personal" -prune -o -user hermes -print0 \
        | xargs -0r chmod u+w,g+w
    '';
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ config.age.secrets.hermes-env.path ];

    hermesHomeFiles = {
      "SOUL.md" = ./hermes/SOUL.md;
      # Personal skills, version-controlled here
      "skills/personal/use-claude/SKILL.md" = ./hermes/skills/use-claude/SKILL.md;
    };

    # The google-workspace skill (Gmail, Calendar, Drive, Docs, Sheets) prefers
    # the gws CLI and points it at Hermes's own google_token.json; its Python
    # fallback libraries are already in the default package.
    # Skill scripts (google_api.py, setup.py) run via the terminal tool and
    # import Hermes's own modules, so `python3` must be Hermes's sealed venv.
    # claude: the bundled claude-code skill delegates coding jobs to Claude
    # Code, signed in with Jack's subscription (CLAUDE_CODE_OAUTH_TOKEN, a
    # 1-year `claude setup-token` token in hermes-env.age; renew by Nov 2027).
    extraPackages = [ pkgs.gws hermesPython pkgs.claude-code pkgs.git ms365Mcp ];

    # Official vendor-hosted MCP servers (OAuth with dynamic client
    # registration; tokens land in .hermes/mcp-tokens/, which restic covers).
    # Log in once from the Mac, tunnelling the callback port:
    #   ssh -L 27891:127.0.0.1:27891 brain \
    #     sudo -u hermes -E hermes mcp login notion     (27892 for todoist)
    # then open the printed URL in the Mac's browser and approve.
    mcpServers = {
      notion = {
        url = "https://mcp.notion.com/mcp";
        auth = "oauth";
      };
      todoist = {
        url = "https://ai.todoist.net/mcp";
        auth = "oauth";
        # search/fetch duplicate the find-* tools; templates are niche
        tools.exclude = [ "search" "fetch" "export-project-template" "import-project-template" ];
      };
      # Hotmail mail + calendar (read-only for now); see ms365Mcp above.
      outlook = {
        command = "${ms365Mcp}/bin/ms365-mcp";
        timeout = 60;
      };
      # Home Assistant on this host via ha-mcp (states, history, statistics,
      # service calls). Token: long-lived token "hermes-brain" on Jack's HA
      # user, in hermes-env.age; Hermes substitutes ${...} at connect time.
      homeassistant = {
        command = "${pkgs.ha-mcp}/bin/ha-mcp";
        env = {
          HOMEASSISTANT_URL = "http://127.0.0.1:8123";
          HOMEASSISTANT_TOKEN = "\${HOMEASSISTANT_TOKEN}";
        };
        # Read and control only. HA's config is code in this repo
        # (services/home-assistant/), so no tools that edit automations,
        # dashboards, devices, zones, or that restart/update/back up HA.
        # (ha_call_service can still call any service, which is the point.)
        tools.include = [
          # reading
          "ha_get_overview" "ha_search" "ha_get_state" "ha_get_entity"
          "ha_get_device" "ha_list_floors_areas" "ha_get_history"
          "ha_eval_template" "ha_get_camera_image" "ha_get_zone"
          "ha_config_get_calendar_events" "ha_get_todo"
          "ha_config_get_automation" "ha_config_get_scene" "ha_config_get_script"
          "ha_config_list_helpers" "ha_config_list_groups"
          "ha_get_automation_traces" "ha_get_logs" "ha_get_system_health"
          "ha_get_skill_guide"
          # controlling (lights, heating, scenes, scripts, helpers...)
          "ha_list_services" "ha_call_service" "ha_bulk_control"
          "ha_get_operation_status"
        ];
      };
    };

    settings = {
      # One OpenRouter balance for every model; switch from Telegram with /model.
      model = {
        provider = "openrouter";
        default = "anthropic/claude-sonnet-5.5";
      };

      timezone = config.time.timeZone;

      # Secrets are stripped from terminal commands unless listed here;
      # Claude Code needs its token.
      terminal.env_passthrough = [ "CLAUDE_CODE_OAUTH_TOKEN" ];

      # Fixed OAuth callback ports so the login can be tunnelled over SSH.
      mcp_servers = {
        notion.oauth = { redirect_host = "localhost"; redirect_port = 27891; };
        todoist.oauth = { redirect_host = "localhost"; redirect_port = 27892; };
      };

      # Side jobs (compaction summaries, titles, the every-10-turns memory
      # review, risky-command approval checks) go to a cheap model.
      auxiliary =
        let cheap = { provider = "openrouter"; model = "deepseek/deepseek-v4.1-flash"; };
        in {
          compression = cheap;
          title_generation = cheap;
          background_review = cheap;
          approval = cheap;
          voice_chat = cheap;
        };

      # If the main model errors or is rate-limited, carry on with this.
      fallback_providers = [
        { provider = "openrouter"; model = "google/gemini-3.6-flash"; }
      ];

      # Voice replies: free Microsoft Edge voices, British. Whether a chat gets
      # voice notes back is per chat: `/voice on` (only after a voice note) or
      # `/voice tts` (always); Hermes keeps that in gateway_voice_mode.json.
      tts = {
        provider = "edge";
        edge.voice = "en-GB-RyanNeural";
      };

      # Voice notes are transcribed on brain (faster-whisper), privately.
      stt = {
        provider = "local";
        echo_transcripts = false;
        # turbo (Whisper large-v3-turbo): much better than small, esp. accents;
        # freed after 10 idle minutes since brain is short on RAM.
        local.model = "turbo";
        local.unload_after_idle_seconds = 600;
      };

      # Telegram: stream replies as they're written, 👀/✅/❌ reactions while
      # working, and keep the model's reasoning out of the chat.
      streaming.enabled = true;
      telegram.reactions = true;
      display.show_reasoning = false;

      # Keep the one long Telegram chat small: compact at 120k tokens rather
      # than at a fraction of Sonnet's 1M window (Vellum ran at ~587k/reply).
      compression = {
        enabled = true;
        threshold_tokens = 120000;
      };

      # Built-in memory only (MEMORY.md + USER.md); no external providers.
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      # state.db otherwise grows forever.
      sessions = {
        auto_prune = true;
        retention_days = 365;
      };
    };
  };
}
