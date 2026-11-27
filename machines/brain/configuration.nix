# Edit this configuration file to define what should be installed on your system. Help is available in the configuration.nix(5) man page, on https://search.nixos.org/options and 
# in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../services/tailscale.nix
      ./../../services/nixarr.nix
      ./../../services/tdarr.nix
      ./../../services/homepage.nix
      ./../../services/home-assistant.nix
      ./../../services/monitoring.nix
      ./../../services/samba.nix
      ./../../services/caddy.nix
      ./../../services/docker.nix
      ./../../services/minuspod.nix
      # ./../../services/n8n.nix
      ./../../services/silverbullet.nix
      ./../../services/notes-git.nix
      ./../../services/terminus.nix
      ./../../services/vellum.nix
      ./../../services/hermes.nix
      ./../../services/backup.nix
      ./../../services/china-review.nix
    ];

  services.vellum.instances = {
    main = {
      domain = "vellum-main.delabere.com";
      port = 7830;
    };
    business = {
      domain = "vellum-business.delabere.com";
      port = 7831;
    };
  };


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "brain";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # networking.hostName = "nixos"; # Define your hostname. Pick only one of the below networking options. networking.wireless.enable = true; # Enables wireless support via 
  # wpa_supplicant. networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  # Configure network proxy if necessary networking.proxy.default = "http://user:password@proxy:port/"; networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";


  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Disable the GNOME3/GDM auto-suspend feature that cannot be disabled in GUI!
  # If no user is logged in, the machine will power down after 20 minutes.
  # systemd.targets.sleep.enable = false;
  # systemd.targets.suspend.enable = false;
  # systemd.targets.hibernate.enable = false;
  # systemd.targets.hybrid-sleep.enable = false;

  security.sudo.extraRules = [
    {
      users = [ "delabere" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];


  # Keep the journal from growing without bound (was 3.9G).
  services.journald.settings.Journal.SystemMaxUse = "1G";

  # Configure console keymap
  console.keyMap = "uk";


  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    users.delabere = {
      isNormalUser = true;
      description = "Jack Rickards";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        #  thunderbird
      ];
    };
    groups = {
      media = {
        members = [ "radarr" "sonarr" "plex" "transmission" "torrenter" "prowlarr" ];
      };
    };
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are started in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  #   enable = true; enableSSHSupport = true;
  # };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Copy of https://github.com/delabere.keys (it was hash-pinned before, so
  # this is the same content). Reading a local file avoids fetching it during
  # evaluation, which forced an x86_64-linux build before a deploy from the Mac
  # could even start evaluating. Refresh with:
  #   curl -fsSL https://github.com/delabere.keys > machines/brain/authorized_keys
  users.users."delabere".openssh.authorizedKeys.keys =
    lib.filter (k: k != "") (lib.splitString "\n" (builtins.readFile ./authorized_keys));

  #Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall altogether. 
  networking.firewall.enable = false;

  # Most users should NEVER change this value after the initial install, for any reason, even if you've upgraded your system to a new NixOS release.
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

  programs = {
    vim.enable = true;
    zsh.enable = true;
  };

  users.users.delabere.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    vim
    stow
    gcc
    lm_sensors
    codex
    claude-code
    antigravity-cli
  ];

  nixpkgs.config.allowUnsupportedSystem = true;
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      # Lets the Mac push closures it built (`nixos-rebuild --target-host`)
      # without signing them.
      trusted-users = [ "root" "delabere" ];
      # Baseline services (grafana + ~7 node servers + 2 chromium renderers)
      # now run ~8-9GB resident on their own. max-jobs=2 let two heavy C++
      # builds (nodejs/v8 + onnxruntime) run at once, each allowed up to
      # `cores` parallel compiles — that plus the baseline blew past 16GB
      # and thrashed swap for hours despite the cgroup cap below (that cap
      # only bounds the build's own footprint, not the whole box). Serialize
      # builds instead so only one heavy compile competes with services.
      max-jobs = 1;
      cores = 4;
    };
    # Builds yield CPU and IO to running services.
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
  };

  # Hard cap on build memory: a runaway build fails instead of freezing the box.
  # Tightened from 6G/2G: with max-jobs=1 this still covers one big build, but
  # leaves more headroom for the growing set of always-on services.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "3G";
    MemoryMax = "4G";
    MemorySwapMax = "1G";
  };

  # Kill the biggest offender before swap is exhausted, rather than thrashing.
  # Raised from 10: trip earlier so we act well before swap is fully pinned
  # and the box has already been unresponsive for a while.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 20;
    extraArgs = [
      "--prefer" "^(cc1plus|cc1|rustc|ld|ld\\.lld|go|node|nix-build|ghc)$"
      "--avoid" "^(sshd|tailscaled|systemd|systemd-journal|dockerd|containerd)$"
    ];
  };

  # Keep remote access alive even under memory pressure.
  systemd.services.sshd.serviceConfig.OOMScoreAdjust = -1000;
  systemd.services.tailscaled.serviceConfig.OOMScoreAdjust = -1000;

  # Custom service to keep only the last 20 system generations
  systemd.services.nix-trim-generations = {
    description = "Keep only the last 20 system generations";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +20
    '';
    startAt = "weekly";
  };

  # sonarr won't work without these
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
    "pnpm-9.15.9"
  ];

  # Writable btop in the browser: only reachable over Tailscale, never the LAN.
  services.ttyd = {
    enable = true;
    interface = "tailscale0";
    writeable = true;
    entrypoint = [ (lib.getExe pkgs.btop) ];
  };
  # tailscale0 only has an address once tailscaled is up; retry until it does.
  systemd.services.ttyd = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.Restart = lib.mkForce "on-failure";
    serviceConfig.RestartSec = 10;
  };
  systemd.services.ttyd.environment.LD_LIBRARY_PATH =
    lib.makeLibraryPath [ pkgs.libwebsockets ];

  # allows users to use port 80 (required for hosting applications as a user)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
}
