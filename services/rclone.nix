{ pkgs, ... }:

# this manages syncing my notes folder, with google Drive
# this is the same folder that silverbullet uses as it's notes source
#
# the result is that I can use silverbullet to edit notes everywhere, but gdrive is a backup
# and additionally any device that has the folder synced, I can use then to edit notes in nvim
# while I am at a desktop if I would like to
{
  systemd.services.rclone-sync = {
    description = "Two-way sync local folder with Google Drive using rclone";
    serviceConfig.Type = "simple";
    path = with pkgs; [ rclone bash ];
    script = ''
      ${pkgs.rclone}/bin/rclone bisync /home/delabere/notes gdrive:notes --resilient --create-empty-src-dirs
    '';
    serviceConfig.User = "delabere"; # run as your user
    serviceConfig.WorkingDirectory = "/home/delabere";
  };

  systemd.timers.rclone-sync = {
    description = "Run rclone sync every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "rclone-sync.service";
    };
  };

  systemd.services.git-auto-commit = {
    description = "Auto-commit and push notes changes to git";
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ git bash openssh ];
    script = ''
      cd /home/delabere/notes

      # Try to fast-forward from remote first
      git pull --ff-only || true

      # Only commit if there are local changes
      if [ -n "$(git status --porcelain)" ]; then
        git add .
        git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        git push
      fi
    '';
    serviceConfig.User = "delabere";
    serviceConfig.WorkingDirectory = "/home/delabere/notes";
  };

  systemd.timers.git-auto-commit = {
    description = "Run git auto-commit every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "1m";
      Unit = "git-auto-commit.service";
    };
  };
}

