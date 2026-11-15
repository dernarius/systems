# System SSD layout, applied by nixos-anywhere (`just anywhere girlboss ...`).
# Only this disk is touched; the ZFS pool drives aren't listed, so disko
# never sees them.
#
#   1G  ESP      /boot, room for lanzaboote's ~50-80M signed images
#   8G  swap     fresh random key every boot (no hibernation on a NAS)
#  rest LUKS2    ext4 /
#
# The LUKS passphrase comes from /tmp/luks.key in the installer, which
# nixos-anywhere fills via --disk-encryption-keys. If the installer sees the
# TPM, a TPM2 slot bound to PCR 7 is enrolled too, so the box can boot
# unattended until the YubiKey replaces it. With Secure Boot still off,
# PCR 7 only proves "same machine, Secure Boot off": it protects the SSD on
# its own (RMA, disposal), not the whole box. Enabling Secure Boot changes
# PCR 7, after which the passphrase is needed once to re-enroll.
{ pkgs, ... }:

let
  keyFile = "/tmp/luks.key";
  luksPart = "/dev/disk/by-partlabel/disk-system-root";
  espPart = "/dev/disk/by-partlabel/disk-system-ESP";
in
{
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S4CNNG0KB18102P";
    # only for `just anywhere-test` (VM disk size), not the real install
    imageSize = "16G";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
            # disko skips mkfs if blkid finds any filesystem, and this SSD had
            # an old ext4 signature where the new ESP starts; clear anything
            # that isn't already vfat
            preCreateHook = ''
              if ! blkid -t TYPE=vfat ${espPart} >/dev/null; then
                wipefs --all ${espPart}
              fi
            '';
          };
        };
        swap = {
          size = "8G";
          content = {
            type = "swap";
            randomEncryption = true;
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = keyFile;
            settings = {
              allowDiscards = true;
              # try the TPM first, fall back to the passphrase prompt
              crypttabExtraOpts = [ "tpm2-device=auto" ];
            };
            postCreateHook = ''
              if [ -e /dev/tpmrm0 ]; then
                ${pkgs.systemd}/bin/systemd-cryptenroll \
                  --unlock-key-file=${keyFile} \
                  --tpm2-device=auto --tpm2-pcrs=7 ${luksPart}
              else
                echo "disko: no TPM in the installer, passphrase only" >&2
              fi
            '';
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
