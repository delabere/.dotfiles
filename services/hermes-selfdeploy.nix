{ config, lib, pkgs, ... }:

# Let Hermes ("Brian") change its own setup through this repo, with Jack's
# approval as a real gate the agent can't fake.
#
#   1. Brian edits its clone of the dotfiles (/var/lib/hermes/dotfiles),
#      commits, and writes the commit hash to /var/lib/hermes/deploy/request.
#   2. hermes-deploy-prepare (root) checks the commit sits on top of GitHub's
#      master, test-builds it, and sends Jack the change summary plus a
#      one-time 6-digit code straight through the Telegram Bot API. The bot
#      never receives its own outgoing messages, so the agent can't see it.
#   3. Jack replies "deploy <code>"; Brian writes the code to
#      /var/lib/hermes/deploy/confirm.
#   4. hermes-deploy-apply (root) checks the code (one attempt, 15 minutes),
#      switches brain to the built system, pushes the commit to GitHub master
#      and reports back. Any wrong code cancels the request.
#
# The agent itself can't push (approvals.deny in services/hermes.nix); only
# the apply step does, after Jack approved. Deploys from the Mac
# (`build-brain`) refuse to run if the Mac is behind GitHub, so they don't
# undo Brian's changes.

let
  home = "/var/lib/hermes";
  repo = "${home}/dotfiles";
  spool = "${home}/deploy";
  runDir = "/run/hermes-deploy";
  chat = config.services.hermes-agent.environment.TELEGRAM_HOME_CHANNEL;
  envFile = config.age.secrets.hermes-env.path;
  remote = "git@github.com:delabere/.dotfiles.git";

  common = ''
    set -euo pipefail
    as_hermes() { runuser -u hermes -- env HOME=${home} "$@"; }
    g() { as_hermes git -C ${repo} "$@"; }
    tg() {
      local token
      token=$(grep '^TELEGRAM_BOT_TOKEN=' ${envFile} | cut -d= -f2-)
      curl -fsS -o /dev/null "https://api.telegram.org/bot$token/sendMessage" \
        --data-urlencode "chat_id=${chat}" --data-urlencode "text=$1" || true
    }
  '';

  tools = with pkgs; [ git nix coreutils curl gnugrep util-linux openssh ];
in
{
  systemd.tmpfiles.rules = [
    "d ${spool} 0770 hermes hermes -"
    "d ${home}/.ssh 0700 hermes hermes -"
  ];

  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # Brian's push key (add the .pub as a write deploy key on the repo) and its
  # clone of the dotfiles. Both live in /var/lib/hermes, so they're backed up.
  systemd.services.hermes-dotfiles = {
    description = "Hermes's deploy key and dotfiles clone";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = tools;
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = common + ''
      key=${home}/.ssh/dotfiles_deploy
      [ -f "$key" ] || as_hermes ssh-keygen -q -t ed25519 -N "" -C "hermes@brain dotfiles" -f "$key"
      printf 'Host github.com\n  IdentityFile %s\n  IdentitiesOnly yes\n' "$key" > ${home}/.ssh/config
      chown hermes:hermes ${home}/.ssh/config
      if [ ! -d ${repo}/.git ]; then
        as_hermes git clone -q ${remote} ${repo} || { echo "clone failed (is the deploy key added?)"; exit 0; }
      fi
      g config user.name "Brian (Hermes)"
      g config user.email "hermes@brain"
    '';
  };

  systemd.paths.hermes-deploy-prepare = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "${spool}/request";
  };
  systemd.services.hermes-deploy-prepare = {
    description = "Test-build Brian's proposed change and send Jack an approval code";
    path = tools;
    serviceConfig.Type = "oneshot";
    script = common + ''
      req=${spool}/request
      [ -s "$req" ] || exit 0
      want=$(tr -dc '0-9a-f' < "$req" | head -c 40); rm -f "$req"
      install -d -m 0700 ${runDir}; rm -f ${runDir}/*

      g fetch -q origin master
      if ! rev=$(g rev-parse --verify -q "$want^{commit}"); then
        tg "Brian's deploy request was rejected: commit $want doesn't exist."; exit 0
      fi
      short=$(g rev-parse --short "$rev")
      if ! g merge-base --is-ancestor origin/master "$rev"; then
        tg "Brian's deploy request ($short) was rejected: it isn't based on GitHub's latest master. Brian should rebase and ask again."; exit 0
      fi
      if [ "$(g rev-parse origin/master)" = "$rev" ]; then
        tg "Brian's deploy request was rejected: $short is already master."; exit 0
      fi

      tg "Brian proposed a change ($short). Test-building it now…"
      log=$(mktemp)
      if ! path=$(as_hermes nix build --no-link --print-out-paths \
            "git+file://${repo}?rev=$rev#nixosConfigurations.brain.config.system.build.toplevel" 2>"$log"); then
        tg "$(printf 'Brian%ss change %s failed to build, so nothing was deployed:\n\n%s' "'" "$short" "$(tail -c 1500 "$log")")"
        exit 0
      fi

      code=$(shuf -i 100000-999999 -n 1)
      echo "$code" > ${runDir}/code
      echo "$rev" > ${runDir}/rev
      echo "$path" > ${runDir}/path
      echo $(( $(date +%s) + 900 )) > ${runDir}/expires

      summary=$(g log --format='• %s' "origin/master..$rev")
      stat=$(g diff --stat origin/master "$rev" | tail -15)
      diff=$(g diff origin/master "$rev" | head -c 1800)
      tg "$(printf 'Brian wants to deploy to brain:\n%s\n\n%s\n\n%s\n\nTo approve, send Brian:  deploy %s\nValid 15 minutes, one try. Ignore it to cancel.' \
        "$summary" "$stat" "$diff" "$code")"
    '';
  };

  systemd.paths.hermes-deploy-apply = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "${spool}/confirm";
  };
  systemd.services.hermes-deploy-apply = {
    description = "Apply Brian's approved change";
    path = tools;
    serviceConfig.Type = "oneshot";
    script = common + ''
      conf=${spool}/confirm
      [ -s "$conf" ] || exit 0
      got=$(tr -dc '0-9' < "$conf" | head -c 6); rm -f "$conf"
      if [ ! -s ${runDir}/code ]; then tg "There's no deploy waiting for approval."; exit 0; fi
      want=$(cat ${runDir}/code); rev=$(cat ${runDir}/rev); path=$(cat ${runDir}/path)
      expires=$(cat ${runDir}/expires)
      rm -f ${runDir}/*   # one attempt only
      if [ "$(date +%s)" -gt "$expires" ]; then tg "That deploy code had expired; nothing was deployed."; exit 0; fi
      if [ "$got" != "$want" ]; then tg "Wrong deploy code, so the request was cancelled and nothing was deployed."; exit 0; fi

      short=$(g rev-parse --short "$rev")
      tg "Approved. Deploying $short to brain…"
      nix-env -p /nix/var/nix/profiles/system --set "$path"
      if ! "$path/bin/switch-to-configuration" switch; then
        tg "Deploying $short failed partway; check 'journalctl -u hermes-deploy-apply' on brain."; exit 0
      fi
      if g push -q origin "$rev:refs/heads/master"; then
        tg "Deployed $short and pushed it to GitHub master. On the Mac, git pull before build-brain."
      else
        tg "Deployed $short, but pushing to GitHub failed. Push it from brain by hand."
      fi
    '';
  };
}
