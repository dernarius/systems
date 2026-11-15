# System-level settings shared by every machine, headless ones included.
# Graphical-only bits live in ./desktop.nix; anything that can live in
# home-manager lives in ../../home instead.
{ lib, pkgs, ... }:

{
  # ZFS hosts override this with a kernel ZFS supports
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  # no kernel cmdline editing at the boot menu (init=/bin/sh etc.)
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;

  # systemd initrd + Plymouth: graphical LUKS prompt, and the path to
  # FIDO2/YubiKey (systemd-cryptenroll) and Secure Boot (lanzaboote) later.
  # Kept on headless machines too: the boot TOTP is shown through Plymouth.
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  # silent boot; everything still lands in the journal
  boot.consoleLogLevel = lib.mkDefault 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    "systemd.show_status=auto"
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vilnius";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.stk = {
    isNormalUser = true;
    description = "Stanislovas";
    extraGroups = [
      "audio"
      "cdrom"
      "dialout"
      "docker"
      "networkmanager"
      "plugdev"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQ35CctJE0EAAABaMp1l4dK5jMNRJ4Pvv9fQjN8J2W3 stk@gnocchi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaHTcU7g2QVepww3v4un7pJlUU6XILcmgjM2dN//1Ny stk@blahaj"
    ];
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.age
    # Secure Boot key management (see ./secure-boot.nix)
    pkgs.sbctl
  ];

  # zsh isn't managed by home-manager, so shell hooks are set up system-wide
  programs.zsh.enable = true;
  programs.direnv.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  services.udisks2.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  virtualisation.docker.enable = true;
}
