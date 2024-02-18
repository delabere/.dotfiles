{
  config,
  pkgs,
  system,
  ...
}: {
  imports = [
    ./base.nix
    ./work-apps.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jackrickards";
  home.homeDirectory =
    {
      aarch64-darwin = "/Users/jackrickards/";
      x86_64-linux = "/home/jackrickards";
    }
    .${system};

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    pkgs.graphviz
    # pkgs.go
    # pkgs.gopls
  ];

  fonts.fontconfig.enable = true;

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      # haven't quite managed to get these working
      #enableAutosuggestions = true;
      #enableCompletion = true;

      initExtra = ''
        # brew is installed here on m1 macs
        [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

        # any .zshrc found can be sourced; its probably a work machine
        [ -f "$HOME/.zshrc" ] && source ~/.zshrc

        # allows easy resetting of home-manager
        function rebuild-home-manager() {
          home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
        }

        function todo() {
            [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes"
            [ ! -f "$HOME/notes/todo.md" ] && touch "$HOME/notes/todo.md"
            nvim "$HOME/notes/todo.md"
        }

        function note() {
            [ ! -d "$HOME/notes" ] && mkdir -p "$HOME/notes"
            [ ! -f "$HOME/notes/$1.md" ] && touch "$HOME/notes/$1.md"
            nvim "$HOME/notes/$1.md"
        }

        # for maintaining and reading a simple braglist
        function brag() {
            [ ! -f "$HOME/brag.md" ] && touch "$HOME/brag.md"
            if [[ -z $1 ]]
            then
              cat $HOME/brag.md
            else
              echo "$(date +%d/%m/%Y) | $1" >> $HOME/brag.md
            fi
        }

        # for maintaining and reading a simple learnlist
        function learnit() {
            [ ! -f "$HOME/learnit.txt" ] && touch "$HOME/learnit.txt"
            if [[ -z $1 ]]
            then
              cat $HOME/learnit.txt
            else
              echo "$(date +%d/%m/%Y) | $1" >> $HOME/learnit.txt
            fi
        }

        function gitprune() {
          git fetch --all -p; git branch -vv | grep ": gone]" | awk '{ print $1 }' | xargs -n 1 git branch -D
        }

        alias lg='lazygit'
        alias gcm='git checkout master && git pull'
        alias cat=bat

        # this one let's me pull all my changes back into the index so I can structure my commits on a more complex
        # pr more easily
        alias reset-commits='git reset --soft $(git merge-base master HEAD)'

        # for pyenv
        export PYENV_ROOT="$HOME/.pyenv"
        command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"

        # The next line updates PATH for the Google Cloud SDK.
        if [ -f '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc'; fi

        # The next line enables shell command completion for gcloud.
        if [ -f '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

        # to enable natural text navigation
        bindkey -e
        bindkey "^[f" forward-word
        bindkey "^[b" backward-word

      '';

      envExtra = ''
        # work configuration
        [ -f $HOME/src/github.com/monzo/starter-pack/zshenv ] && source $HOME/src/github.com/monzo/starter-pack/zshenv

        # custom environment variables
        [ -f $HOME/.dotfiles/env.sh ] && source $HOME/.dotfiles/env.sh

        JAVA_HOME=$(/usr/libexec/java_home -v 19)

        # work related stuff
        s101 () {
          shipper deploy --s101 $1
        }

        shipthis () {
          branch=$(eval "git rev-parse --symbolic-full-name --abbrev-ref HEAD")
          shipper deploy --s101 $branch
        }

        prod () {
          shipper deploy --prod $1
        }

        function mergeship() {
            local PRNumber=$(gh pr view $(git branch --show-current) --json url --template "{{.url}}") &&\
            gh pr merge -sd &&\
            echo "Shipping $PRNumber to production with automated rollback" &&\
            shipper deploy --s101 --disable-progressive-rollouts --skip-confirm-rollout $PRNumber &&\
            shipper deploy --prod --skip-confirm-rollout $PRNumber
        }

        function tpr() {
            # Check if sufficient arguments are provided
            if [ $# -lt 1 ]; then
                echo "Usage: tpr3 [ticket URL or ID] [optional: base branch] [optional: PR title]"
                return 1
            fi

            local ticket_id=$(echo "$1" | awk -F '/' '{print $NF}')

            # Setting base branch
            local base_branch="master"  # Default value
            if [ -n "$2" ]; then
                base_branch="$2"
            fi

            local commit_msg="init"
            local pr_title="$3"
            local use_jira_title="yes"

            # Change to "no" if a PR title is provided
            [ -n "$pr_title" ] && use_jira_title="no"

            # Check if the branch already exists
            if git rev-parse --verify "$ticket_id" >/dev/null 2>&1; then
                echo "Branch $ticket_id already exists."
                return 1
            fi

            # Fetch ticket details from Jira only if needed
            if [ "$use_jira_title" = "yes" ]; then
                # Use environment variables for credentials
                local jira_domain="https://mondough.atlassian.net"
                local jira_user="$JIRA_USER"
                # get your jira api token from here https://id.atlassian.com/manage-profile/security/api-tokens
                local jira_api_token="$JIRA_API_TOKEN"

                local pr_title=$(curl -s -u "$jira_user:$jira_api_token" \
                                -H "Content-Type: application/json" \
                                -X GET \
                                "$jira_domain/rest/api/latest/issue/$ticket_id" | jq -r '.fields.summary')

                if [ -z "$pr_title" ]; then
                    echo "Failed to fetch Jira ticket title."
                    return 1
                fi
            fi

            # Checkout the base branch and pull the latest changes
            git checkout "$base_branch" && git pull || { echo "Failed to checkout and update $base_branch."; return 1; }

            # Create new branch
            git checkout -b "$ticket_id" || { echo "Failed to create branch $ticket_id."; return 1; }

            # Commit and push
            git commit -m "$commit_msg" --allow-empty && git push || { echo "Failed to commit and push changes."; return 1; }

            # Create a pull request
            gh pr create --title "[$ticket_id] $pr_title" --draft --fill || { echo "Failed to create pull request."; return 1; }

            }
      '';
    };

    direnv.enable = true;
    fzf.enable = true;
    starship.enable = true;
    starship.settings = {
      command_timeout = 2000;
    };
    autojump.enable = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    jq.enable = true;

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };

    neovim = {
      enable = true;
      vimAlias = true;
    };

    tmux = {
      enable = true;
      prefix = "C-a";
      mouse = true;
      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.power-theme
        tmuxPlugins.resurrect
        tmuxPlugins.continuum
      ];

      extraConfig = ''
        # let copying use default clipboard
        unbind C-y
        unbind C-p
        bind C-y run "tmux save-buffer - | xclip -i -sel clipboard"
        bind C-p run "tmux set-buffer "$(xclip -o -sel clipboard)"; tmux paste-buffer"

        # change window splits key
        unbind %
        bind v split-window -h

        unbind '"'
        bind s split-window -v

        unbind r
        bind r source-file ~/.tmux.conf

        # pane resizing with vi binds
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5
        # maximise window
        bind -r m resize-pane -Z

        set-window-option -g mode-keys vi

        # vi bindings for copy mode
        bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
        bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

        # enable mouse pane resizing
        unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode after dragging with mouse
      '';
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/delabere/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
