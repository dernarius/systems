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
