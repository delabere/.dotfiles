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
      echo "hello"
      ${pkgs.rclone}/bin/rclone bisync /home/delabere/notes gdrive:notes --resync --create-empty-src-dirs --log-file=/home/delabere/rclone-sync.log --log-level INFO

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

}

