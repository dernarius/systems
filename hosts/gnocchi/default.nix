# ThinkPad T14 Gen 6 (Intel) laptop
{ inputs, pkgs-unstable, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-intel-gen6
    ./hardware-configuration.nix
    ../common/secure-boot.nix
  ];

  networking.hostName = "gnocchi";

  boot.kernelParams = [ "zswap.enabled=1" ];

  # Hibernate target. The scripted initrd probed swapDevices for an image on
  # its own; the systemd initrd only resumes from resume= or the EFI
  # HibernateLocation variable, so name it explicitly.
  boot.resumeDevice = "/dev/mapper/luks-079c0b46-cfb3-4ebc-9dcb-d54f0e27a75b";

  services.hardware.bolt.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
  };

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # fingerprint is only used by hyprlock itself
  security.pam.services.sudo.fprintAuth = false;
  security.pam.services.su.fprintAuth = false;
  security.pam.services.hyprlock.fprintAuth = false;

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-vulkan;
  };

  home-manager.users.stk.imports = [ ./home.nix ];

  system.stateVersion = "23.11"; # Did you read the comment?
}
