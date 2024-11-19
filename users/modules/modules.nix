{ pkgs
, system
, config
, ...
}: {
  imports = [
    ./shell/base.nix
    ./shell/work.nix
    ./go.nix
  ];
}
