# Mount brain's Samba share at /Volumes/delabere on login.
# The Resolve projects (e.g. China2026) link their media from there.
# At home it mounts over the LAN (192.168.1.11) so video doesn't go through the
# Tailscale tunnel; away from home it falls back to brain's Tailscale name.
# Either way the share is the same, so the mount point and Resolve's paths are too.
# A per-user agent (via Home Manager, so nix-darwin needs no primaryUser): the
# share password lives in the login Keychain, which `mount volume` reads
# silently; a root daemon couldn't.
{ pkgs, ... }:
let
  lanHost = "192.168.1.11";
  bonjourHost = "brain._smb._tcp.local"; # advertised by avahi on brain (services/samba.nix)
  tailscaleHost = "brain";
  mountBrain = pkgs.writeShellScript "mount-brain-share" ''
    log() { echo "$(/bin/date): $*" >&2; }
    mounted() { /sbin/mount | /usr/bin/grep -q "on /Volumes/delabere "; }
    on_tailscale() { /sbin/mount | /usr/bin/grep "on /Volumes/delabere " | /usr/bin/grep -q "@${tailscaleHost}/"; }
    at_home() { /sbin/ping -c 1 -t 1 ${lanHost} >/dev/null 2>&1; }
    try_mount() {
      /usr/bin/osascript -e 'try' -e "mount volume \"smb://$1/delabere\"" -e 'end try' >/dev/null 2>&1
    }

    # Self-heal: mounted through Tailscale while we're at home (e.g. brain rebooted and the
    # share came back over the tunnel). That's ~10x slower for video, so move it to the LAN,
    # but only when nothing has files open on it (unmounting under Resolve would break it).
    if mounted && on_tailscale && at_home; then
      if /usr/sbin/lsof +f -- /Volumes/delabere >/dev/null 2>&1; then
        log "share is on Tailscale at home but files are open; leaving it"
        /usr/bin/osascript -e 'display notification "Quit Resolve and other apps using it to switch to the home network." with title "brain share is on Tailscale (slow)"' >/dev/null 2>&1
        exit 0
      fi
      log "share is on Tailscale at home; remounting over the LAN"
      /usr/sbin/diskutil unmount /Volumes/delabere >/dev/null 2>&1 || exit 0
    fi

    # retry for ~5 min while the network comes up after login or wake
    for i in $(/usr/bin/seq 1 30); do
      mounted && exit 0
      # LAN first, only if brain answers there (i.e. we're at home). Prefer its
      # Bonjour name so Finder shows "brain"; fall back to the raw LAN address.
      if at_home; then
        try_mount ${bonjourHost}
        mounted || try_mount ${lanHost}
      # Only use Tailscale once the LAN has been unreachable for ~2 min, so a brain reboot or a
      # slow Wi-Fi join at home doesn't leave the share stuck on the tunnel.
      elif [ "$i" -gt 12 ]; then
        try_mount ${tailscaleHost}
      fi
      mounted && exit 0
      /bin/sleep 10
    done
    log "could not mount brain's share"
    exit 1
  '';
in
{
  home-manager.users.delabere.launchd.agents.mount-brain-share = {
    enable = true;
    config = {
      ProgramArguments = [ "${mountBrain}" ];
      RunAtLoad = true;
      StartInterval = 900; # re-check every 15 min (after sleep, Wi-Fi changes)
      StandardErrorPath = "/tmp/mount-brain-share.log";
    };
  };

  # SMB packet signing costs a lot of throughput on macOS; brain is on the home
  # LAN or reached through Tailscale (already encrypted), so don't require it.
  environment.etc."nsmb.conf".text = ''
    [default]
    signing_required=no
  '';

  # don't litter network shares with .DS_Store files
  home-manager.users.delabere.targets.darwin.defaults."com.apple.desktopservices".DSDontWriteNetworkStores = true;
}
