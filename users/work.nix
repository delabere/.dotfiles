{ pkgs, ... }: {
  imports = [
    ./modules/modules.nix # optional extras, enabled through config options
    ./modules/core.nix # essentials which should be included in all configurations
  ];

  home.username = "jackrickards";

  shell = {
    base.enable = true;
    work.enable = true;
  };

  languages.go = {
    enable = true;
    work = true;
  };

  # use this for packages that haven't permanently made it into this config
  # if they have a more permanent place in the config then they should live
  # in a module and be set by an option
  home.packages = with pkgs; [
    graphviz

    # web
    nodejs_24
    typescript

    cargo # needed to compile pbls, protobuf lsp
    protols


    scrcpy # for droid
  ];

  programs = {
    zsh = {
      envExtra = ''
        # work configuration
        [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv

        # custom environment variables
        [ -f $HOME/.dotfiles/env.sh ] && source $HOME/.dotfiles/env.sh

        JAVA_HOME=$(/usr/libexec/java_home -v 19)

        function find_service() {
            base_dir="$HOME/src/github.com/monzo/wearedev"
            selected=$(find -E "$base_dir" -type d -regex ".*(service|cron|web)\.[^/]*" -maxdepth 1 | sed "s|$base_dir/||" | fzf)

            if [[ -n "$selected" ]]; then
                # Extract the part after the dot
                svc=''${selected#*.}
                echo "$svc"
            fi
        }

        function k() {
            local svc=$(find_service)
            echo "Running kib $1 $svc"
            kib $1 "$svc"
        }

        function g() {
            local svc=$(find_service)
            echo "Running graf $1 $svc"
            graf $1 "$svc"
        }

      '';
    };
  };
}
