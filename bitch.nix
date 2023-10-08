{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];
  ec2.hvm = true;

  networking.hostName = "bitch";

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];

  users.users = {
    delabere = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGI4GMdpBy7A5Ug9oyjZxC2O1D/Y8eDAA7g7WFA+XFseDXdsYnNzOWB5J2unefX40jRL2E0zZfujiFvHH9LuLMINUTbbnfQOwujBgJfTYEPH57SEgxKzwJVnzkMYdn8UsVCI6SevrxENSsQA5df0Olynsauqk1AnKpHlrCVvZfK/5dFFAst3aU1X5vjiBzrUwaL6HZ4uDbSgVaEwa09F39vpGzy4//IggQmteI2gAEN9PkRUiGr4o+YZA1yScrxe4UmWcOIkpZ8i8K4EZUteayTEBSmFzAOYyZ1BijjntBTs4w8lTRO+q7O9g3oPEluf+qwyLpc3fnWho0uNCEtkAN5Oq5eBraoOHp0tKuv3rN0fkBCvG/a/Rw9D3y0D+2OZZrE4RhPKygMm1XwHa2Q1NewzAqdN989NR6i3IvJPKVjK4atV5R4bDCins/m+vdOYhT4ASBs9q0kXboSNEXBwFdHC5uuClDPflR3Fq/26eezpuEDiwWTcGYtyAYfGajVnE= delabere@Jacks-MacBook-Pro.local"
      ];
      shell = pkgs.zsh;
    };
  };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.delabere = import ./delabere.nix;
  home-manager.extraSpecialArgs = {
    system = "x86_64-linux";
  };

  programs.zsh.enable = true;

  environment.systemPackages = [
    pkgs.btop
  ];

  system.stateVersion = "23.11";
}
