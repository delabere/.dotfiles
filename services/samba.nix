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
        "server string" = "brain";
        "netbios name" = "brain";
        "security" = "user";
        "passdb backend" = "tdbsam";
        "follow symlinks" = "yes";
        # macOS clients (Finder, Resolve): store Mac metadata in xattrs instead
        # of ._ files, faster directory listings, atomic renames
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
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
      "plex-media" = {
        "path" = "/mnt/bigboi/PlexMedia";
        "browseable" = "yes";
        "writable" = "yes";
        "read only" = "no";
        "valid users" = "delabere";
        "force user" = "nobody";
        "force group" = "nogroup";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
      "tdarr-cache" = {
        "path" = "/mnt/bigboi/tdarr-cache";
        "browseable" = "yes";
        "writable" = "yes";
        "read only" = "no";
        "valid users" = "delabere";
        "force user" = "nobody";
        "force group" = "nogroup";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # Bonjour: advertise the share to Macs as "brain" (Finder's Network list and
  # sidebar), reachable as brain.local on the LAN. Samba registers itself with avahi.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
    # nixpkgs' Samba doesn't register itself with avahi, so advertise it here
    extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name>brain</name>
        <service><type>_smb._tcp</type><port>445</port></service>
        <service><type>_device-info._tcp</type><port>0</port><txt-record>model=RackMac</txt-record></service>
      </service-group>
    '';
  };

  # so samba works on windows
  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
  };

}
