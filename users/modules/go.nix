{ pkgs
, system
, config
, ...
}:
let
  mkOption = pkgs.lib.mkOption;
  types = pkgs.lib.types;

  go_pkgs = with pkgs; [
    go
    gopls
  ];

  go_work_pkgs = with pkgs; [
    go_1_22
    gotest
    goprotomocker
    gopls
  ];

in
{
  options = {
    languages.go.enable = mkOption {
      type = types.bool;
      default = false;
      description = "..."; # TODO:
    };
    languages.go.work = mkOption {
      type = types.bool;
      default = false;
      description = "..."; # TODO:
    };
  };

  config = {
    home.packages =
      if config.languages.go.enable && config.languages.go.work then
        go_work_pkgs
      else if config.languages.go.enable then
        go_pkgs
      else [ ];
  };
}
