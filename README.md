# Dotfiles
This repo actually does a lot more than manage dotfiles

Follow the steps below to completely set up a new or existing machine


This setup uses nix home-manager to install software to get you from 0-productive as fast as possible

Dotfiles themselves are managed as part of the nix configurations such as in `delabere.nix`

## Nix installation
We're using a rust installer which is fast, and doesn't require you to explicitly allow experimental features (which we need for flakes support)
```$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install```
(https://zero-to-nix.com/concepts/nix-installer#using)

## Home-Manager setup
Point home-manager at our "flakified" repo. You need to use the correct configuration in your flake syntax depending on what aarch you are using. 
These are defined [here](https://github.com/delabere/.dotfiles/blob/89ff1dcf20294a49e08580f7b323e96d47173cec/flake.nix#L34-L37)

Build the following command depending on the configuration you need and run:

```$ nix run home-manager/master switch -- --flake github:delabere/.dotfiles#delabere-aarch64-darwin```

After you've run the above you can use the local home manager for subsequent set-ups:

```$ home-manager switch --flake ~/.dotfiles#work-aarch64-darwin```

But an even easier way is just to run:

```$ switch```

which just runs the same as above, but will always use the correct flake for the initialised configuration

You might find cases where you've pushed a change that is not being recognised by home-manager when using the git flake syntax. If that's happening, use the --reload argument to force a re-download.

```$ home-manager switch --flake github:delabere/.dotfiles#delabere-aarch64-darwin --refresh```

## Nvim setup
Neovim gets installed as part of the home-manager setup. But it won't find your configuration in the default home directory (`~/.config/nvim/`) unless you stow the nvim directory first.


Stow creates a sym-link to the directory in our repo so that if you pull new changes in, nvim knows about it right away.

Just run:
`$ stow nvim` 

## (optional) Install brew packages for mac
`$ brew bundle`
