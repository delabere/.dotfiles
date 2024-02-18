{
  config,
  pkgs,
  system,
  ...
}: let
  switch = pkgs.writeShellScriptBin "switch" ''
    home-manager switch --flake ~/.dotfiles#lakeview-aarch64-linux
  '';
in {
  imports = [
    ./base.nix
    ./base-apps.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ubuntu";
  home.homeDirectory =
    {
      aarch64-linux = "/home/ubuntu";
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
    switch
    pkgs.alejandra
    pkgs.delve
    pkgs.go
    pkgs.gopls
    pkgs.lazygit
    pkgs.niv
    pkgs.nixpkgs-fmt
    pkgs.nodePackages.vscode-html-languageserver-bin
    pkgs.nodejs
    pkgs.ranger
    pkgs.ripgrep
    pkgs.stow
    pkgs.sumneko-lua-language-server
    pkgs.thefuck
    pkgs.tldr
    pkgs.tree
    pkgs.watch
    pkgs.xclip
    pkgs.zsh
    (pkgs.nerdfonts.override {
      fonts = ["FiraCode" "Hack"];
    })
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
        # so that when mac updates we add nix back into the zshrc file
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        # brew is installed here on m1 macs
        [[ $OSTYPE == 'darwin'* ]] && export PATH=/opt/homebrew/bin:$PATH

        # any .zshrc found can be sourced; its probably a work machine
        [ -f "$HOME/.zshrc" ] && source ~/.zshrc

        # allows easy resetting of home-manager
        function rebuild-home-manager() {
          home-manager -f $HOME/.dotfiles/configuration.nix switch "$@"
        }

        alias lg='lazygit'
        alias gcm='git checkout master && git pull'

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

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
