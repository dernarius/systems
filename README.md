# systems

One flake for every machine, with home-manager running as a NixOS module so a
single `nixos-rebuild` updates the system and `~` together.

```
flake.nix
justfile             every command below; `just` lists them
hosts/
  common/            NixOS settings every machine needs (boot, nix, user, greetd,
                     swayfx, pipewire, docker, tailscale, keyd, steam, ...)
  gnocchi/           ThinkPad: nixos-hardware, tlp, lid/upower, fprint, ollama-vulkan
    home.nix         laptop-only home bits: kanshi, batsignal, touchpad, battery
  blahaj/            desktop: AMD, xpadneo, ratbagd, sshd, ollama-rocm, TV mode
    home.nix         desktop-only home bits: kanshi monitors, amdgpu_top, piper
    audio-toggle.nix toggle-audio-output between the two DACs

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
