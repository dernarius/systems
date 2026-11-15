# Graphical machines: sway, greetd, audio, bluetooth, gaming. Imported for
# every host that also gets home-manager (see mkDesktop in flake.nix);
# headless machines only get ./default.nix.
{ pkgs, ... }:

{
  imports = [ ./gaming.nix ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };
}
