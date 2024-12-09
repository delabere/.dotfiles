let
  brain-delabere = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJR9tysfHoxnqC8zHobi2j+ZXcT9+Osyb/6897z3aTjB";
  brain-system = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImTP7fayVD9tp3MHLAz5dWm2pBaeB0B5nazCqhcFRUF";
in
{
  "tailscale-authkey.age".publicKeys = [ brain-delabere brain-system ];
}
