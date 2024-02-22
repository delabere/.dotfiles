{
  config,
  pkgs,
  system,
  name,
  ...
}: {
  imports = [
    ./config/base_lite.nix
    ./config/shell/base.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ubuntu";
}
