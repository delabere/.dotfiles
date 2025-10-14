{ config, pkgs, ... }: {

  # to get folders set up for sharing
  # sudo chown -R nobody:nogroup share
  # sudo chmod -R 0775 share
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "passdb backend" = "tdbsam";
        "follow symlinks" = "yes";
      };
      "public" = {
        "path" = "/mnt/bigboi/share";
        "public" = "yes";
        "browseable" = "yes";
        "writable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      "delabere" = {
        "path" = "/mnt/bigboi/share";
        "browseable" = "yes";
        "writable" = "yes";
        "read only" = "no";
        "valid users" = "delabere";
        "force user" = "nobody";
        "force group" = "nogroup";
        "create mask" = "0664";
        "directory mask" = "0775";
        "wide links" = "yes";
      };
    };
  };

  # so samba works on windows
  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
  };

}
