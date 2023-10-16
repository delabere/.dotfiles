# dotfiles
my dotfiles

## install nix
https://nixos.org/download.html

https://zero-to-nix.com/concepts/nix-installer#using

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install


## stow the home-manager and nvim directories
`stow home-manager && stow nvim` 

## uninstall stow (it will be installed with nix)
`brew uninstall stow`

## build home with nix
`home-manager switch`

## (optional) install brew packages
`brew bundle`
