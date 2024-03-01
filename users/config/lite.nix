{
  config,
  pkgs,
  brag,
  session-x,
  system,
  ...
}: {
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.homeDirectory =
    {
      "x86_64-linux" = "/home/${config.home.username}";
      "aarch64-darwin" = "/Users/${config.home.username}";
      "aarch64-linux" = "/home/${config.home.username}";
    }
    .${system};

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      # haven't quite managed to get these working
      enableAutosuggestions = true;
      enableCompletion = true;

      initExtra = ''
        # so that when mac updates we add nix back into the zshrc file
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        # brew is installed here on m1 macs
        [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

        # any .zshrc found can be sourced; its probably a work machine
        [ -f "$HOME/.zshrc" ] && source ~/.zshrc

        alias lg='lazygit'
        alias gcm='git checkout master && git pull'
        alias cat=bat

        # this one let's me pull all my changes back into the index so I can structure my commits on a more complex
        # pr more easily
        alias reset-commits='git reset --soft $(git merge-base master HEAD)'

        # The next line updates PATH for the Google Cloud SDK.
        if [ -f '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/path.zsh.inc'; fi

        # The next line enables shell command completion for gcloud.
        if [ -f '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/delabere/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

        # to enable natural text navigation
        bindkey -e
        bindkey "^[f" forward-word
        bindkey "^[b" backward-word

        # this is required to get ranger not to crash:
        # https://github.com/ranger/ranger/issues/2583#issuecomment-1206290600
        # fix is in ranger 1.9.4, we should be able to remove this when/if it is released
        # export TERM=xterm-256color
      '';
    };

    direnv.enable = true;
    fzf.enable = true;
    starship.enable = true;
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
      escapeTime = 10;
      terminal = "screen-256color";

      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.power-theme
        tmuxPlugins.resurrect
        tmuxPlugins.continuum
        {
          plugin = session-x.packages.${system}.default;
          extraConfig = ''
            set -g @sessionx-filter-current 'false'
          '';
        }
        {
          plugin = tmuxPlugins.jump;
          extraConfig = ''
            set-option -g @jump-key 'J'
          '';
        }
      ];

      extraConfig = ''
        # bind the second prefix for more split keyboard
        set-option -g prefix2 C-b

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
  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    btop
    gh
    lazygit
    ranger
    ripgrep
    stow
    tldr
    tree
    watch
    xclip
    marksman
    (nerdfonts.override {
      fonts = ["JetBrainsMono" "Iosevka" "FiraCode" "Hack"];
    })
  ];
}
