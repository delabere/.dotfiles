# Edit this configuration file to define what should be installed on your system. Help is available in the configuration.nix(5) man page, on https://search.nixos.org/options and 
# in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "brain";
  # networking.hostName = "nixos"; # Define your hostname. Pick only one of the below networking options. networking.wireless.enable = true; # Enables wireless support via 
  # wpa_supplicant. networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/London";

  # Configure network proxy if necessary networking.proxy.default = "http://user:password@proxy:port/"; networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.delabere = {
    isNormalUser = true;
    description = "Jack Rickards";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run: $ nix search wget environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default. wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are started in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  #   enable = true; enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  # users.users."delabere".openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzFCNGbA9pwrs6fSxV1A4EG6Kfuzw81GSXoPrVSZSwg delabere@Jacks-MacBook-Pro.local"
  # ];
  # users.users.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzFCNGbA9pwrs6fSxV1A4EG6Kfuzw81GSXoPrVSZSwg delabere@Jacks-MacBook-Pro.local"
  # ];

  users.users."delabere".openssh.authorizedKeys.keys =
    let
      authorizedKeys = pkgs.fetchurl {
        url = "https://github.com/delabere.keys";
        sha256 = "sha256-i9rarqkXLTlBvUCeN3H9uzogq8loo5WQUA6kbmDBISM=";
      };
    in
    pkgs.lib.splitString "\n" (builtins.readFile
      authorizedKeys);

  #Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall altogether. 
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system (/run/current-system/configuration.nix). This is useful in case you accidentally delete 
  # configuration.nix. system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine, and is used to maintain compatibility with application data (e.g. databases) 
  # created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason, even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from, so changing it will NOT upgrade your system - see 
  # https://nixos.org/manual/nixos/stable/#sec-upgrading for how to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration, and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

  programs.vim.enable = true;

  # programs.git = {
  #   enable = true;
  #   userName = "delabere";
  #   userEmail = "jack.rickards@hotmail.co.uk";
  # };
  programs.zsh.enable = true;
  users.users.delabere.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default. wget
    stow
    gcc
  ];

  nixpkgs.config.allowUnsupportedSystem = true;
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
  };

}
