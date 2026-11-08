# swayfx itself is installed by the system (hosts/common); this only writes
# ~/.config/sway/config. Outputs, inputs and other hardware-specific bits are
# added from hosts/<name>/home.nix.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.wayland.windowManager.sway.config;
  mod = cfg.modifier;
  modeSystem = "(l)ock, (s)uspend, (h)ibernate, (r)eboot, (Shift+s)hutdown";
  # keycodes 10..19 are the number row, so workspaces work on the lt layout too
  workspaceKeys = lib.genList (i: {
    code = toString (10 + i);
    ws = toString (i + 1);
  }) 10;
in
{
  # tools the keybindings and startup commands call
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    pamixer
    playerctl
    pa-notify
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    checkConfig = false;

    config = {
      modifier = "Mod1";
      terminal = "alacritty";
      menu = "rofi -show drun";

      fonts = {
        names = [ "Monofur Nerd Font" ];
        size = 14.0;
      };

      workspaceAutoBackAndForth = true;
      floating.modifier = mod;
      # keep sway's defaults rather than home-manager's i3-flavoured ones
      focus = {
        wrapping = "yes";
        newWindow = "urgent";
      };

      gaps.inner = 20;
      window = {
        border = 0;
        titlebar = false;
        commands = [
          {
            criteria.title = "^.*";
            command = ''title_format ""'';
          }
        ];
      };

      output."*".bg = "${./wallpaper.jpg} fill";

      input."type:keyboard" = {
        xkb_layout = "us,lt";
        xkb_options = "grp:lwin_toggle";
      };

      startup = [ { command = "pa-notify -t 2"; } ];

      keybindings = {
        "${mod}+Return" = "exec ${cfg.terminal}";
        "${mod}+Shift+q" = "kill";
        "${mod}+d" = "exec ${cfg.menu}";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";
        "${mod}+Shift+s" = ''exec grim -g "$(slurp)" - | wl-copy'';

        "XF86AudioMute" = "exec pamixer --toggle-mute";
        "XF86AudioLowerVolume" = "exec pamixer --decrease 5";
        "XF86AudioRaiseVolume" = "exec pamixer --increase 5";
        "XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioPrev" = "exec playerctl previous";
        "XF86AudioNext" = "exec playerctl next";

        "${mod}+${cfg.left}" = "focus left";
        "${mod}+${cfg.down}" = "focus down";
        "${mod}+${cfg.up}" = "focus up";
        "${mod}+${cfg.right}" = "focus right";
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";

        "${mod}+Shift+${cfg.left}" = "move left";
        "${mod}+Shift+${cfg.down}" = "move down";
        "${mod}+Shift+${cfg.up}" = "move up";
        "${mod}+Shift+${cfg.right}" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        "${mod}+Shift+m" = "move workspace to output right";
        "${mod}+Shift+n" = "move workspace to output down";

        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+f" = "fullscreen";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";

        "${mod}+minus" = ''mode "${modeSystem}"'';
        "${mod}+r" = ''mode "resize"'';
      };

      keycodebindings = lib.listToAttrs (
        lib.concatMap (k: [
          (lib.nameValuePair "${mod}+${k.code}" "workspace number ${k.ws}")
          (lib.nameValuePair "${mod}+Shift+${k.code}" "move container to workspace number ${k.ws}")
        ]) workspaceKeys
      );

      modes = {
        ${modeSystem} = {
          l = ''exec ${config.hyprlock.lockCommand}, mode "default"'';
          s = ''exec systemctl suspend, mode "default"'';
          h = ''exec systemctl hibernate, mode "default"'';
          r = ''exec systemctl reboot, mode "default"'';
          "Shift+s" = ''exec systemctl poweroff, mode "default"'';
          Return = ''mode "default"'';
          Escape = ''mode "default"'';
        };
        resize = {
          ${cfg.left} = "resize shrink width 10px";
          ${cfg.down} = "resize grow height 10px";
          ${cfg.up} = "resize shrink height 10px";
          ${cfg.right} = "resize grow width 10px";
          Left = "resize shrink width 10px";
          Down = "resize grow height 10px";
          Up = "resize shrink height 10px";
          Right = "resize grow width 10px";
          Return = ''mode "default"'';
          Escape = ''mode "default"'';
        };
      };
    };

    extraConfig = ''
      # swayfx
      blur enable

      include /etc/sway/config.d/*
    '';
  };

  services.swayidle = {
    enable = true;
    events.before-sleep = config.hyprlock.lockCommand;
  };
}
