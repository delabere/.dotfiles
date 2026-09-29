{ pkgs, ... }:

# Auto-commits and pushes the notes folder (silverbullet's notes source) to git.
{
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

