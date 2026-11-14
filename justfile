host := `hostname`

root := "run0"

# list recipes
default:
    @just --list --unsorted

# flakes only see files git knows about
[private]
stage:
    git add -A

### everyday

# rebuild and switch this machine
switch: stage
    {{ root }} nixos-rebuild switch --flake .#{{ host }}

# rebuild and switch this machine, reinstall booloader
switch-w-bootloader: stage
    {{ root }} nixos-rebuild switch --flake .#{{ host }} --install-bootloader

# rebuild and activate on next boot only
boot: stage
    {{ root }} nixos-rebuild boot --flake .#{{ host }}

# activate without making it the boot default (reboot to undo)
test: stage
    {{ root }} nixos-rebuild test --flake .#{{ host }}

# build a host without activating and show what would change
diff target=host: stage
    nixos-rebuild build --flake .#{{ target }}
    nix store diff-closures /run/current-system ./result

# update all inputs (or just the named ones), switch, commit flake.lock
update *inputs: stage
    nix flake update {{ inputs }}
    -git commit -m "flake update" flake.lock

# roll back to the previous system generation
rollback:
    {{ root }} nixos-rebuild switch --rollback

# boot into the firmware setup on the next reboot (no reboot now; `false` cancels)
firmware on="true":
    {{ root }} bootctl reboot-to-firmware {{ on }}

# PCRs the boot-time TOTP is sealed to (see hosts/common/secure-boot.nix)
totp_pcrs := "0,2,7"

# create the TPM-sealed boot TOTP secret and show its QR code (once per machine)
totp-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    read -rsp "tpm2-totp recovery password: " pw; echo
    {{ root }} tpm2-totp -p {{ totp_pcrs }} -b SHA256 -l "TPM2-TOTP {{ host }}" -P "$pw" generate

# re-seal the boot TOTP to the current PCR values (after a BIOS update etc.)
totp-reseal:
    #!/usr/bin/env bash
    set -euo pipefail
    read -rsp "tpm2-totp recovery password: " pw; echo
    {{ root }} tpm2-totp -p {{ totp_pcrs }} -b SHA256 -P "$pw" reseal

# show the current boot TOTP (compare with the authenticator app)
totp:
    {{ root }} tpm2-totp -t calculate

# evaluate every host
check: stage
    nix flake check

# format all nix files
fmt:
    nix fmt

# delete generations older than a week and collect garbage
gc:
    {{ root }} nix-collect-garbage --delete-older-than 7d
    nix-collect-garbage --delete-older-than 7d

# open a repl with this flake loaded
repl:
    nix repl .

### backups

# the duplicity URL a host's config backs up to
[private]
backup-target from:
    @nix eval --raw .#nixosConfigurations.{{ from }}.config.home-manager.users.stk.backup.target

# start an incremental backup now
backup:
    systemctl --user start incremental-backup

# start a new full backup chain
backup-full:
    systemctl --user start full-backup

# follow the backup logs
backup-log:
    journalctl --user -u incremental-backup -u full-backup -f

# show the backup chains of a host
backup-status from=host:
    PASSPHRASE= duplicity collection-status "$(just backup-target {{ from }})"

# restore a host's latest backup into a directory (needs its gpg key imported)
restore from=host dest=(env("HOME") / "restore"):
    PASSPHRASE= duplicity restore "$(just backup-target {{ from }})" {{ dest }}
