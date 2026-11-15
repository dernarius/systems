# systems

One flake for every machine, with home-manager running as a NixOS module so a
single `nixos-rebuild` updates the system and `~` together. Desktops are built
with `mkDesktop` (common + desktop + home-manager), headless machines with
`mkHost` (common only).

```
flake.nix
justfile             every command below; `just` lists them
hosts/
  common/            NixOS settings every machine needs (boot, nix, user, docker,
                     tailscale, avahi, ...)
    desktop.nix      graphical machines only: greetd, swayfx, pipewire,
                     bluetooth, keyd, thunar, steam (gaming.nix)
    secure-boot.nix  lanzaboote + boot TOTP, imported per host
    serial-totp.nix  boot TOTP as text lines on a serial/USB-serial port (headless)
  gnocchi/           ThinkPad: nixos-hardware, tlp, lid/upower, fprint, ollama-vulkan
    home.nix         laptop-only home bits: kanshi, batsignal, touchpad, battery
  blahaj/            desktop: AMD, xpadneo, ratbagd, sshd, ollama-rocm, TV mode
    home.nix         desktop-only home bits: kanshi monitors, amdgpu_top, piper
    audio-toggle.nix toggle-audio-output between the two DACs
  girlboss/          headless NAS: ZFS pool `newtent`, docker compose services,
                     dnsmasq for tailscale; no desktop, no home-manager
    disko.nix        system SSD layout: ESP, random-key swap, LUKS ext4 root

home/
  default.nix        the full home config: core + packages + backup
  core.nix           the desktop core (also what the installer gets)
    sway.nix         ~/.config/sway/config, swayidle, the tools sway calls
    status.nix       i3status + swaybar
    alacritty.nix rofi.nix hyprlock.nix
    wallpaper.jpg
  packages.nix       apps, dev tools, games, firefox
  lazy.nix           launchers that build an app on first run (modrinth-app)
  backup.nix         duplicity user services/timer (key id set per host)
```

## Everyday

```sh
just switch          # rebuild + switch this machine
just diff            # build and show what would change, without switching
just update          # nix flake update, switch, commit flake.lock
just rollback
```

`flake.lock` is shared, so update on one machine, push, and on the other
`git pull && just switch`. Flakes only see files git knows about; the recipes
`git add -A` first.

greetd logs straight into sway and hyprlock starts with it, so the lock
screen is the login screen.

## Apps built on first launch

`modrinth-app` is unfree, so it's never in the binary cache and would be
compiled on every machine with every update. Instead it's wrapped with
`home/lazy.nix`: rebuilds skip it, and the first launch after an update
builds it (with a notification) and keeps it under `~/.local/state/lazy`.
The build log is next to it. Any other heavy package can be wrapped the
same way in `home/packages.nix`.

## Reinstalling girlboss (nixos-anywhere)

girlboss is installed over SSH: nixos-anywhere kexecs it into an installer
in RAM, disko wipes and partitions the system SSD from
`hosts/girlboss/disko.nix`, then NixOS is installed from this flake. The ZFS
pool drives aren't in the disko config and are never touched.

```sh
just anywhere-test girlboss          # build it, check disko's layout in a VM
# on girlboss: stop the compose stack, then `sudo zpool export newtent`
just stash girlboss                  # tailscale state + ~stk -> ~/stash/girlboss
just anywhere girlboss stk@192.168.88.247
```

- Use the LAN IP: after kexec there's no tailscale and no MagicDNS.
- `anywhere` asks for the new LUKS passphrase, keeps the SSH host keys
  (`--copy-host-keys`) and copies `~/stash/<host>` into the new system.
- If the installer sees the TPM, a TPM2 slot (PCR 7) is enrolled next to the
  passphrase, so the box reboots unattended. Without one, the first boot
  waits for the passphrase on a keyboard.
- Anything else on the old system drive is gone: check the docker volumes
  (`docker volume ls`) before.

After the YubiKey arrives:
`systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-system-root`
and `--wipe-slot=tpm2` if the TPM slot should go. Turning on Secure Boot
changes PCR 7: unlock with the passphrase once, then re-enroll the TPM with
`--wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7`.

## Backups

The incremental runs every 2 hours as a user timer. Everything home-manager
writes into `~` is excluded automatically, since it's rebuilt from this repo.

```sh
just backup / backup-full / backup-log
just backup-status [host]
just restore [host] [dest]     # into ~/restore by default
```

## Migrating from the old `~/.config` repos

The old repos were checked out *as* `~/.config`. home-manager now owns
`sway`, `alacritty`, `rofi`, `hypr`, `i3status` and `kanshi` there, so the repo
has to move out. On each machine:

```sh
# 1. turn the nvim submodule into a standalone clone so it survives step 2
cd ~/.config
rm nvim/.git
mv .git/modules/nvim nvim/.git
git -C nvim config --unset core.worktree

# 2. retire the old repo (keep it around until you're happy)
mv ~/.config/.git ~/old-config-git

# 3. clone this repo somewhere outside ~/.config and switch
git clone <this repo> ~/systems
cd ~/systems && just switch
```

Any old file in the way gets renamed to `*.hm-bak` rather than blocking the
switch; delete those once everything looks right.

nvim is deliberately left unmanaged: `~/.config/nvim` stays a plain clone of
`dernarius/nvchad-starter`.
