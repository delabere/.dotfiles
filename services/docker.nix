{ config, pkgs, ... }: {

  # In /etc/nixos/configuration.nix
  virtualisation.docker = {
    enable = true;

    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Optional: Add your user to the "docker" group to run docker without sudo
  users.users.delabere.extraGroups = [ "docker" ];

  users.users.delabere.linger = true;
}
