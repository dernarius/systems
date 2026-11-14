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
    # TESTING (2026-11-14): hard resets with MCE bank 5 (EX watchdog timeout)
    # at stock settings, under light load (browsing, games). Limit idle to C1
    # to rule out CC6 wake-up hangs. Remove if a CPU swap fixes it.
    "processor.max_cstate=1"
  ];

  # BIOS P10.60 hands over an 800x600 GOP mode; ask for the highest one so the
  # boot menu and early console aren't low-res.
  boot.loader.systemd-boot.consoleMode = "max";

  # Hibernate target (34G encrypted swap, 31G RAM). The systemd initrd only
  # resumes from resume= or the EFI HibernateLocation variable.
  boot.resumeDevice = "/dev/mapper/luks-5125b327-06ff-4cbc-b8b2-5c55603f71de";

  # early KMS so Plymouth comes up at native resolution without a mode switch
  # (gnocchi gets xe from nixos-hardware)
  boot.initrd.kernelModules = [ "amdgpu" ];

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
