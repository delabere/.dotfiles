{ config, pkgs, ... }: {

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "map to guest" = "bad user";
      };
      "public" = {
        "path" = "/mnt/bigboi/share";
        "browseable" = "yes";
        "writable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # so samba works on windows
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

}
