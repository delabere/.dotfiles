# Link a self-hosted Vellum assistant to a Vellum Platform account so it can
# run on Vellum credits. Mirrors `vellum login` (cli/src/commands/login.ts):
# WorkOS PKCE sign-in -> ensure-registration -> inject the assistant API key.
# `domains` (instance -> hostname) is prepended by services/vellum.nix.

export DOCKER_HOST=unix:///run/docker.sock
platform="${VELLUM_PLATFORM_URL:-https://platform.vellum.ai}"
platform="${platform%/}"

name="${1:-}"
if [ -z "$name" ] || [ -z "${domains[$name]:-}" ]; then
  echo "usage: vellum-link <$(IFS='|'; echo "${!domains[*]}")>" >&2
  echo "       VELLUM_SESSION_TOKEN=... vellum-link <instance>   # skip the sign-in" >&2
  exit 1
fi
ctr="vellum-$name-assistant"

# Call a daemon route over IPC from inside the container, so the side effects
# the HTTP route has (provider refresh, CES notify) run. Params come on stdin
# so secrets never land in argv.
ipc() {
  docker exec -i -w /app/assistant "$ctr" bun -e '
    const { cliIpcCall } = await import("/app/assistant/src/ipc/cli-client.ts");
    const r = await cliIpcCall(process.argv[1], JSON.parse(await Bun.stdin.text()));
    console.log(JSON.stringify(r));
    process.exit(r.ok ? 0 : 1);
  ' "$1"
}

inject() {
  # $1 = credential name (service:field); value from $VALUE.
  local out
  export VALUE
  out=$(jq -n --arg n "$1" '{body: {type: "credential", name: $n, value: env.VALUE}}' | ipc secrets_add) || {
    echo "Failed to store $1: $out" >&2
    exit 1
  }
}

b64url() { base64 -w0 | tr '+/' '-_' | tr -d '='; }

# --- 1. Platform session -----------------------------------------------------
session="${VELLUM_SESSION_TOKEN:-}"
if [ -z "$session" ]; then
  providers=$(curl -fsS "$platform/_allauth/app/v1/config")
  provider=$(jq -c '[.data.socialaccount.providers[]
      | select(.openid_configuration_url == null
               and ((.flows // []) | index("provider_token"))
               and (.client_id | type == "string"))][0]' <<<"$providers")
  client_id=$(jq -r .client_id <<<"$provider")
  provider_id=$(jq -r .id <<<"$provider")

  verifier=$(openssl rand 32 | b64url)
  challenge=$(printf %s "$verifier" | openssl dgst -sha256 -binary | b64url)
  state=$(openssl rand -hex 16)
  # Nothing listens here; the browser's failed load is where the code shows up.
  redirect="http://127.0.0.1:53682/auth/callback"
  authorize=$(jq -rn --arg c "$client_id" --arg r "$redirect" --arg ch "$challenge" --arg s "$state" \
    '"https://api.workos.com/user_management/authorize?client_id=\($c|@uri)&redirect_uri=\($r|@uri)&response_type=code&scope=openid%20profile%20email&code_challenge=\($ch)&code_challenge_method=S256&state=\($s)&provider=authkit"')

  echo "1. Open this on any device and sign in to Vellum:"
  echo
  echo "   $authorize"
  echo
  echo "2. The browser then fails to load a 127.0.0.1 page. Copy that page's full"
  echo "   address from the address bar and paste it here."
  echo
  read -r -p "Callback URL: " callback
  query="${callback#*\?}"
  param() { sed -n "s/.*\(^\|&\)$1=\([^&#]*\).*/\2/p" <<<"$query"; }
  code=$(param code)
  if [ -z "$code" ] || [ "$(param state)" != "$state" ]; then
    echo "That URL has no code or a mismatched state; start again." >&2
    exit 1
  fi

  access=$(jq -n --arg c "$client_id" --arg code "$code" --arg v "$verifier" \
      '{client_id: $c, grant_type: "authorization_code", code: $code, code_verifier: $v}' |
    curl -fsS -X POST -H 'Content-Type: application/json' --data-binary @- \
      https://api.workos.com/user_management/authenticate | jq -r '.access_token // empty')
  [ -n "$access" ] || { echo "WorkOS code exchange failed." >&2; exit 1; }

  # The CLI sends provider "workos"; fall back to the id the platform advertises.
  for pid in workos "$provider_id"; do
    session=$(ACCESS=$access jq -n --arg p "$pid" --arg c "$client_id" \
        '{provider: $p, process: "login", token: {client_id: $c, access_token: env.ACCESS}}' |
      curl -sS -X POST -H 'Content-Type: application/json' --data-binary @- \
        "$platform/_allauth/app/v1/auth/provider/token" | jq -r '.meta.session_token // empty')
    [ -n "$session" ] && break
  done
  [ -n "$session" ] || { echo "Platform session exchange failed." >&2; exit 1; }
fi

email=$(curl -fsS -H "X-Session-Token: $session" "$platform/_allauth/app/v1/auth/session" |
  jq -r '.data.user.email // "unknown"')
org=$(curl -fsS -H "X-Session-Token: $session" "$platform/v1/organizations/" | jq -r '.results[0].id // empty')
[ -n "$org" ] || { echo "No organization found for $email." >&2; exit 1; }
echo "Signed in as $email (org $org)"

# --- 2. Register this assistant ----------------------------------------------
# Stable per host and instance, so re-running re-confirms rather than duplicates.
installation=$(printf 'vellum-link:%s' "$(cat /etc/machine-id)" | sha256sum | cut -d' ' -f1)
body=$(jq -n --arg i "$installation" --arg n "$name" --arg v "$VELLUM_VERSION" --arg u "https://${domains[$name]}" \
  '{client_installation_id: $i, runtime_assistant_id: $n, client_platform: "cli",
    assistant_version: ($v | ltrimstr("v")), public_ingress_url: $u}')
platform_post() {
  curl -fsS -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' \
    -H "X-Session-Token: $session" -H "Vellum-Organization-Id: $org" \
    --data-binary "$body" "$platform/v1/assistants/self-hosted-local/$1/"
}
registration=$(platform_post ensure-registration)
echo "Registered as $(jq -r '.assistant.name + " (" + .assistant.id + ")"' <<<"$registration")"

# The key is only returned on first registration. Afterwards keep the one the
# assistant holds unless the platform rejects it, else rotate (the old key
# stays valid for a grace period).
key=$(jq -r '.assistant_api_key // empty' <<<"$registration")
if [ -z "$key" ]; then
  status=$(echo '{}' | ipc platform_verify_credential | jq -r '.result.status // empty' || true)
  if [ "$status" != "valid" ]; then
    echo "Provisioning a replacement API key..."
    key=$(platform_post reprovision-api-key | jq -r '.provisioning.assistant_api_key // empty')
    [ -n "$key" ] || { echo "Reprovisioning returned no key." >&2; exit 1; }
  fi
fi

# --- 3. Hand the credentials to the assistant --------------------------------
VALUE=$platform inject vellum:platform_base_url
VALUE=$(jq -r '.webhook_secret // empty' <<<"$registration")
[ -n "$VALUE" ] && inject vellum:webhook_secret
if [ -n "$key" ]; then
  VALUE=$key inject vellum:assistant_api_key
fi
unset VALUE key session access

# --- 4. Route the default profiles through Vellum credits --------------------
docker exec "$ctr" assistant inference providers default vellum
echo
docker exec "$ctr" assistant platform status
