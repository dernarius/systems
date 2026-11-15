# Headless NAS: ZFS pool `newtent` holds all the data, services run from a
# docker compose file on it. No desktop, no home-manager.
#
# The system SSD is LUKS (./disko.nix), installed with nixos-anywhere; see
# the README. Later, once there's a YubiKey: enroll it with
# systemd-cryptenroll, import ../common/secure-boot.nix, and move the data to
# an encrypted dataset. With no screen, the boot TOTP goes to a serial port
# instead: import ../common/serial-totp.nix and set
# `boot.serialTotp.enable = true;` (ttyS0, 9600 8N1 by default; USB serial
# works too, see the module).
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "girlboss";
  # required by ZFS; must not change or the pool won't import
  networking.hostId = "5c5a2971";

  # ZFS lags behind mainline, so stay on the LTS kernel instead of _latest
  boot.kernelPackages = pkgs.linuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "newtent" ];
  # root is ext4, so this only matters once the system drive moves to ZFS
  boot.zfs.forceImportRoot = false;

  # Pinned: files on the pool are owned by these numbers, and a reinstall
  # would otherwise hand out whatever ids are free.
  users.users.stk.uid = 1000;
  users.users.server = {
    isSystemUser = true;
    description = "server";
    uid = 993;
    group = "server";
  };
  users.groups.server.gid = 991;

  security.sudo.extraRules = [
    {
      users = [ "stk" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    ncdu
    unzip
    wget
    zfs
    syncthing
    macchina
    abcde
    zellij
    flac
    tree-sitter
  ];

  services.openssh.enable = true;

  # docker (and `docker compose`) comes from virtualisation.docker in common
  virtualisation.docker.daemon.settings.dns = [ "192.168.88.1" ];

  networking.firewall.enable = false;

  systemd.services.wg-tunnel-route-fix = {
    description = "Exempt WireGuard tunnel subnet from Tailscale routing table";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.iproute2}/bin/ip rule add to 10.10.10.0/30 lookup main priority 5260";
      RemainAfterExit = true;
    };
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      bind-interfaces = false;
      bind-dynamic = true;
      no-resolv = true;
      no-hosts = true;
      address = "/qunty.fyi/100.114.225.72";
    };
  };

  systemd.services.dnsmasq = {
    after = [
      "tailscaled.service"
      "sys-subsystem-net-devices-tailscale0.device"
    ];
    wants = [ "sys-subsystem-net-devices-tailscale0.device" ];
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
