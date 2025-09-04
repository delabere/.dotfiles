# Edit this configuration file to define what should be installed on your system. Help is available in the configuration.nix(5) man page, on https://search.nixos.org/options and 
# in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./../../services/tailscale.nix
      ./../../services/nixarr.nix
      ./../../services/homepage.nix
      ./../../services/home-assistant.nix
      ./../../services/monitoring.nix
      ./../../services/samba.nix
      # ./../../services/docker.nix
      ./../../services/n8n.nix
      ./../../services/silverbullet.nix
      # ./../../services/librechat_beta.nix
    ];


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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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
        members = [ "radarr" "sonarr" "plex" "transmission" "torrenter" ];
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

  users.users."delabere".openssh.authorizedKeys.keys =
    let
      githubKeys = user: sha256:
        let
          file =
            pkgs.fetchurl {
              url = "https://github.com/${user}.keys";
              sha256 = sha256;
            };
          contents = builtins.readFile file;
        in
        lib.splitString "\n" contents;

      delabereKeys = githubKeys "delabere" "sha256-auNnTulhj3ypQa7hTAfb5f7YJpV+IQK7ppC29x8lVfU=";
      # olehKeys = githubKeys "stolyaroleh" "sha256-nU4h0fTLZ8AThYk1V8X+sEyqUO3ly2kwRJEgmVho6TU=";
    in
    delabereKeys;

  #Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall altogether. 
  networking.firewall.enable = false;

  # Most users should NEVER change this value after the initial install, for any reason, even if you've upgraded your system to a new NixOS release.
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

  programs = {
    firefox.enable = true;
    vim.enable = true;
    zsh.enable = true;
  };

  users.users.delabere.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    vim
    stow
    gcc
    lm_sensors
  ];

  nixpkgs.config.allowUnsupportedSystem = true;
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
  };

  # sonarr won't work without these
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.428"
    "aspnetcore-runtime-6.0.36"
  ];

  services.ttyd = {
    enable = true;
    writeable = true;
    entrypoint = [ (lib.getExe pkgs.btop) ];
  };

  # allows users to use port 80 (required for hosting applications as a user)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
}
