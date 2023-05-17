# dotfiles
my dotfiles

## install nix
https://nixos.org/download.html

## enable flakes
add the following to `/etc/nix/nix.conf`
`experimental-features = nix-command flakes`

## install stow
`brew install stow` - other package managers are available

## setting up Tmux
`tmux` - open tmux
`tmux source ~/.tmux.conf` - load config
`ctrl+a I` - install plugins

## when OSX does an update sometimes you will lose some important cofig from your `zshrc` which will stop nvim/tmux from working
`sudo vim /etc/zshrc`
add the following lines if they are missing from the bottom of your file:
```zshrc
# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
```
## stow the home-manager and nvim directories
`stow home-manager && stow nvim` 

## uninstall stow (it will be installed with nix)
`brew uninstall stow`

## build home with nix
`home-manager switch`

## (optional) install brew packages
`brew bundle`
