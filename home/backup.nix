# duplicity backups of ~ to girlboss. The incremental runs every 2 hours;
# `systemctl --user start full-backup` makes a new full chain.
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.backup;
  home = config.home.homeDirectory;
  # everything home-manager writes into ~ is rebuilt from this repo
  managedFiles = map (f: f.target) (lib.filter (f: f.enable) (lib.attrValues config.home.file));
  duplicity =
    mode:
    lib.escapeShellArgs (
      [
        "${pkgs.duplicity}/bin/duplicity"
        mode
        "--encrypt-sign-key"
        cfg.encryptKey
      ]
      ++ lib.concatMap (path: [
        "--exclude"
        "${home}/${path}"
      ]) (lib.unique (cfg.exclude ++ managedFiles))
      ++ [
        home
        cfg.target
      ]
    );
  service = mode: {
    Unit.Description = "duplicity ${mode} backup of ${home}";
    Service = {
      Type = "oneshot";
      Environment = [ "PASSPHRASE=" ];
      ExecStart = duplicity mode;
    };
  };
in
{
  options.backup = {
    encryptKey = lib.mkOption {
      type = lib.types.str;
      description = "GPG key id used to encrypt and sign the backup.";
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Paths relative to the home directory to leave out.";
    };
    target = lib.mkOption {
      type = lib.types.str;
      default = "scp://girlboss//mnt/newtent/stk/${osConfig.networking.hostName}";
    };
  };

  config = {
    backup.exclude = [
      ".cache"
      ".bun"
      ".mozilla"
      ".steam"
      ".local/share/Steam"
      "Games"
      ".config/discord/Cache"
      # home-manager / nix profile state, recreated on activation
      ".nix-profile"
      ".local/state/nix"
      ".local/state/home-manager"
    ];

    systemd.user.services.incremental-backup = service "incremental";
    systemd.user.services.full-backup = service "full";

    systemd.user.timers.backup = {
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnBootSec = "2 hours";
        OnUnitActiveSec = "2 hours";
        Unit = "incremental-backup.service";
      };
    };
  };
}
