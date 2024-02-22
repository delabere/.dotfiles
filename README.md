# Dotfiles
This repo actually does a lot more than manage dotfiles

Follow the steps below to completely set up a new or existing machine


This setup uses nix home-manager to install software to get you from 0-productive as fast as possible

Dotfiles themselves are managed as part of the nix configurations such as in `delabere.nix`

## Nix installation
We're using a rust installer which is fast, and doesn't require you to explicitly allow experimental features (which we need for flakes support)
```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
(https://zero-to-nix.com/concepts/nix-installer#using)

## Home-Manager setup
Point home-manager at our "flakified" repo. You need to use the correct configuration in your flake syntax depending on what aarch you are using.
These are defined [here](https://github.com/delabere/.dotfiles/blob/89ff1dcf20294a49e08580f7b323e96d47173cec/flake.nix#L34-L37)

Build the following command depending on the configuration you need and run:
```sh
nix run github:delabere/.dotfiles#switch.work
```

## Nvim setup
If you didn't use home-manager to set up nvim, you will need to move the config in this repo into your default home directory (`~/.config/nvim/`).
Stow is used for this.

Stow creates a symlink to the directory in our repo so that if you pull new changes in, nvim knows about it right away.

Just run:
```sh
stow nvim
```

## (optional) Install brew packages for mac
```sh
brew bundle
```
