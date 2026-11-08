# System-level settings shared by every machine. Anything that can live in
# home-manager lives in ../../home instead.
{ pkgs, ... }:

{
  imports = [ ./gaming.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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
  networking.firewall.allowedTCPPorts = [
    # development stuff (8080 is also the TV mode switcher API on blahaj)
    6969
    8000
    8080
    # syncthing (runs from home-manager, which can't open ports)
    22000
  ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];

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
  ];

  # zsh isn't managed by home-manager, so shell hooks are set up system-wide
  programs.zsh.enable = true;
  programs.direnv.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # The compositor itself is installed system-wide so greetd, polkit and the
  # portals are wired up; its configuration lives in home/sway.nix.
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.swayfx}/bin/sway";
        user = "stk";
      };
      default_session = initial_session;
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # needs a setuid wrapper, so it can't come from home-manager
  programs.wshowkeys.enable = true;

  # hyprlock (configured in home/hyprlock.nix) authenticates through this
  security.pam.services.hyprlock = { };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-shares-plugin
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services.gnome.gnome-keyring.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };

  virtualisation.docker.enable = true;
}
