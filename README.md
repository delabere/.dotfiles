# dotfiles
my dotfiles

created using GNU Stow and this https://www.jakewiesler.com/blog/managing-dotfiles guide

# setup
for installing these dotfiles onto a new machine

# install nix
https://nixos.org/download.html

# run nix home-manager
1. first run `$ nix-shell`
this will use `shell.nix` to learn what `home-manager` is
2. then run `$home-manager -f configuration.nix switch`
this will spin up the environment according to the contents of `configuration.nix`

# link dotfiles
This gets a little bit confusing because I have a few different dotfiles for my shells

- `.bashrc.local` - for all machines
- `.bashrc.work` - for just my work machine
- `.zshrc.local` - for all machines
- `.zshrc.work` - for just my work machine

this part of `configuration.nix` creates new `.bashrc` and `.zshrc` files,
```nix
...
  programs.bash = {
    enable = true;

    bashrcExtra = ''
      if [ -f ~/.bashrc.local ]; then
        source ~/.bashrc.local
      fi
      if [ -f ~/.bashrc.work ]; then
        source ~/.bashrc.work
      fi
    '';
  };

  programs.zsh = {
    enable = true;

    initExtra = ''
    '';
  };
...
```

which will conflict with any existing `...rc` files on the system, throwing this error:
```sh
Existing file '/Users/jackrickards/.bashrc' is in the way of '/nix/store/n4cahg6xfkrsqzr50sxj280hr17sy3ab-home-manager-files/.bashrc'
Existing file '/Users/jackrickards/.zshrc' is in the way of '/nix/store/n4cahg6xfkrsqzr50sxj280hr17sy3ab-home-manager-files/.zshrc'
Existing file '/Users/jackrickards/.local/share/nvim/site/autoload/plug.vim' is in the way of '/nix/store/n4cahg6xfkrsqzr50sxj280hr17sy3ab-home-manager-files/.local/share/nvim/site/autoload/plug.vim'
Existing file '/Users/jackrickards/.bash_profile' is in the way of '/nix/store/n4cahg6xfkrsqzr50sxj280hr17sy3ab-home-manager-files/.bash_profile'
Please move the above files and try again or use 'home-manager switch -b backup' to back up existing files automatically.
```

there is one more conflict in there which is caused by an existing `vim-plug` install
```sh
Existing file '/Users/jackrickards/.local/share/nvim/site/autoload/plug.vim' is in the way of '/nix/store/n4cahg6xfkrsqzr50sxj280hr17sy3ab-home-manager-files/.local/share/nvim/site/autoload/plug.vim'
```

if you are getting this then you need to remove it and re-build
```sh
$ rm '/Users/jackrickards/.local/share/nvim/site/autoload/plug.vim'  
```

## install stow
`brew install stow` - other package managers are available
## stow 'em
stow each directory in the `.dotfiles` directory
e.g. `$ stow nvim`

