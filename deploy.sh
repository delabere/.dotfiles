#!/bin/bash
set -euo pipefail
profile="/nix/var/nix/profiles/system"
bitch="ec2-3-253-21-86.eu-west-1.compute.amazonaws.com"

nixos-rebuild build --flake .#bitch
system=$(readlink result)
nix-copy-closure --to $bitch $system
ssh $bitch sudo nix-env --profile $profile --set $system
ssh $bitch sudo $profile/bin/switch-to-configuration switch
