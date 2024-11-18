{ pkgs
, ...
}: {
  imports = [
    ./modules/modules.nix # optional extras, enabled through config options
    ./modules/core.nix # essentials which should be included in all configurations
  ];

  home.username = "ubuntu";

  # use this for packages that haven't permanently made it into this config
  # if they have a more permanent place in the config then they should live
  # in a module and be set by an option
  home.packages = with pkgs; [
  ];
}
