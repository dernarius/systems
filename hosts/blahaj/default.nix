# AMD desktop
{ pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./tv-mode.nix
  ];

  networking.hostName = "blahaj";

  boot.kernelParams = [
    "amd_pstate=active"
    # JMicron USB-SATA bridge: use usb-storage instead of flaky UAS
    "usb-storage.quirks=152d:0562:u"
  ];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;
  hardware.xpadneo.enable = true;

  # gaming mouse configuration (piper is in ./home.nix)
  services.ratbagd.enable = true;

  services.avahi.publish = {
    enable = true;
    addresses = true;
    workstation = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = false;
  };

  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-rocm;
  };

  home-manager.users.stk.imports = [ ./home.nix ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
