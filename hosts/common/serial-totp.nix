# Boot TOTP on a serial port, for machines without a screen: while the initrd
# runs, the current tpm2-totp code is written to a serial port as a plain
# text line, for a small serial display to show. Same secret and PCRs as the
# Plymouth one in ./secure-boot.nix (`just totp-setup`).
#
# Output is dumb on purpose: "<host> 123456\r\n" per line, no ANSI escapes,
# "<host> TOTP FAIL" when the TPM refuses to unseal (PCRs changed: firmware
# update, Secure Boot keys, or tampering), and "<host> booted" once the
# initrd hands over to the real system, so a stale code never stays up.
# The line repeats every few seconds, so a display that is plugged in or
# resets mid-boot catches up quickly.
#
# Works with an on-board UART (ttyS0) or USB serial: ttyUSB* (FTDI, CP210x,
# CH340, PL2303 adapters) or ttyACM* (boards with native USB: Pico,
# ESP32-S3, Arduino Leonardo/Micro, ...). For USB, prefer a stable name like
# "serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0", copied from
# `ls /dev/serial/by-id` on the running system.
#
# Does not put a kernel console or getty on the port, so nothing else
# writes to the display.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.boot.serialTotp;
  host = lib.escapeShellArg config.networking.hostName;
  dev = "/dev/${cfg.port}";
  device = "${utils.escapeSystemdPath dev}.device";
  # -hupcl: keep DTR up between writes, or boards that reset on DTR
  # (most Arduinos) would reboot on every line
  setup = "stty -F ${dev} ${toString cfg.baud} cs8 -parenb -cstopb -crtscts clocal -hupcl raw -echo";
  # re-run setup on every write: a replugged USB device comes back with
  # default settings
  # (and never fail: the unit script runs under `set -e`)
  send = msg: "{ ${setup} && printf '%s %s\\r\\n' ${host} ${msg} > ${dev}; } 2>/dev/null || true";
in
{
  options.boot.serialTotp = {
    enable = lib.mkEnableOption "showing the boot TOTP on a serial port";
    port = lib.mkOption {
      type = lib.types.str;
      default = "ttyS0";
      example = "serial/by-id/usb-FTDI_FT232R_USB_UART_A50285BI-if00-port0";
      description = "Serial device the code is written to, relative to /dev.";
    };
    baud = lib.mkOption {
      type = lib.types.int;
      default = 9600;
      description = "Baud rate (8N1, no flow control). Ignored by native USB (ttyACM) boards.";
    };
    interval = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Seconds between lines.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable && config.boot.initrd.systemd.tpm2.enable;
        message = "boot.serialTotp needs the systemd initrd with TPM2 support.";
      }
    ];

    environment.systemPackages = [ pkgs.tpm2-totp ];

    boot.initrd.systemd.initrdBin = [ pkgs.tpm2-totp ];

    # USB serial drivers, loaded by udev when a matching device shows up
    boot.initrd.availableKernelModules = [
      "cdc_acm"
      "usbserial"
      "ftdi_sio"
      "cp210x"
      "ch341"
      "pl2303"
    ];

    # the initrd only ships a few of udev's rules; this one makes
    # /dev/serial/by-id and /dev/serial/by-path
    boot.initrd.services.udev.packages = [
      (pkgs.runCommand "initrd-udev-serial-rules" { } ''
        mkdir -p $out/etc/udev/rules.d
        ln -s ${config.boot.initrd.systemd.package}/lib/udev/rules.d/60-serial.rules $out/etc/udev/rules.d
      '')
    ];

    boot.initrd.systemd.services.serial-totp = {
      description = "Show the boot TOTP on ${dev}";
      wantedBy = [ "sysinit.target" ];
      wants = [ device ];
      after = [
        "tpm2.target"
        device
      ];
      conflicts = [ "initrd-switch-root.target" ];
      before = [ "initrd-switch-root.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "exec";
      script = ''
        while true; do
          if code=$(tpm2-totp calculate 2>/dev/null); then
            ${send ''"$code"''}
          else
            ${send "'TOTP FAIL'"}
          fi
          sleep ${toString cfg.interval}
        done
      '';
      postStop = ''
        ${send "booted"}
      '';
    };
  };
}
