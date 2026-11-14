# Secure Boot via lanzaboote: signed unified kernel images (kernel + initrd +
# cmdline) instead of plain systemd-boot entries. Import per host once its
# keys exist; not part of ./default.nix.
#
# Per-host setup (keys live outside the repo and must be backed up):
#   1. run0 sbctl create-keys       # -> /var/lib/sbctl
#   2. import this module, `just boot`, then `run0 sbctl verify`
#   3. reboot once with Secure Boot still off to check the signed path boots
#   4. firmware in Setup Mode, then: run0 sbctl enroll-keys --microsoft
#      (--microsoft is required: GPU/firmware option ROMs are MS-signed)
{ inputs, lib, ... }:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # lanzaboote replaces the systemd-boot installer; it still reads
  # systemd-boot.{configurationLimit,consoleMode,editor} for loader.conf
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Show a TPM-sealed TOTP on the Plymouth screen; only type the LUKS
  # passphrase if it matches the authenticator app. The secret is created at
  # runtime with `just totp-setup` (PCRs 0,2,7: firmware, option ROMs, Secure
  # Boot state/keys). Not PCR 4: lanzaboote changes it every generation.
  # Re-run `just totp-reseal` after a BIOS update or Secure Boot key change.
  boot.plymouth.tpm2-totp.enable = true;
}
