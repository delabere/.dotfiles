# Dotfiles
This repo actually does a lot more than manage dotfiles
Follow the steps below to completely set up a new or existing machine

This setup uses nix home-manager to install software to get you from 0-productive as fast as possible

Dotfiles themselves are managed as part of the nix configurations such as in `delabere.nix`

## Nix installation
```$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install```
(https://zero-to-nix.com/concepts/nix-installer#using)

## Home-Manager setup
Point home-manager at the flake in this repo. You need to use the correct configuration depending on what aarch you are using and these are defined [here](https://github.com/delabere/.dotfiles/blob/89ff1dcf20294a49e08580f7b323e96d47173cec/flake.nix#L34-L37)
Build the following command depending on the configuration you need and run:
```$ nix run home-manager/master switch -- --flake github:delabere/.dotfiles/oleh-and-jack-hack#delabere-aarch64-darwin```

After you've run the above you can use the local home manager for subsequent set-ups:
```$ home-manager switch --flake github:delabere/.dotfiles/oleh-and-jack-hack#delabere-aarch64-darwin```

## Nvim setup
Neovim will have been installed already as part of the home-manager setup. But it won't be able to find the configuration in the default home directory unless you stow the nvim directory.
Stow sym-links the directory so that if you pull changes to the dotfiles repo, nvim knows about it right away.

Just run:
`$ stow nvim` 

## (optional) Install brew packages for mac
`$ brew bundle`
