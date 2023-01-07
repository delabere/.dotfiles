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

# link dotfiles
## install stow
`brew install stow` - other package managers are available
## stow 'em
stow each directory in the `.dotfiles` directory
e.g. `$ stow nvim`
