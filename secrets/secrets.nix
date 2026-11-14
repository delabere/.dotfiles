let
  brain-delabere = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJR9tysfHoxnqC8zHobi2j+ZXcT9+Osyb/6897z3aTjB";
  brain-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImTP7fayVD9tp3MHLAz5dWm2pBaeB0B5nazCqhcFRUF";
  # the Mac can decrypt backup secrets too, so a dead brain does not take the backup password with it
  mac-delabere = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdLIPjNtTfsZOF26lnwe0+uYKt/LVaA9iMwHGQnSXwo";
in
{
  "tailscale-authkey.age".publicKeys = [ brain-delabere brain-system ];
  "nordvpn-wireguard.conf.age".publicKeys = [ brain-delabere brain-system ];
  "homepage-env.age".publicKeys = [ brain-delabere brain-system ];
  "minuspod-env.age".publicKeys = [ brain-delabere brain-system ];
  "restic-password.age".publicKeys = [ brain-delabere brain-system mac-delabere ];
  "rclone-conf.age".publicKeys = [ brain-delabere brain-system mac-delabere ];
}
