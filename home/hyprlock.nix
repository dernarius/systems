# Fingerprint unlock is turned on wherever the system runs fprintd (gnocchi).
# greetd logs straight into sway, so hyprlock doubles as the login screen.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  fingerprint = osConfig.services.fprintd.enable;
  label = text: y: size: {
    monitor = "";
    inherit text;
    color = "rgba(255, 255, 255, 1.0)";
    font_size = size;
    font_family = "Monofur Nerd Font";
    position = "0, ${toString y}";
    halign = "center";
    valign = "center";
  };
  hyprlock = lib.getExe config.programs.hyprlock.package;
  swayidle = lib.getExe pkgs.swayidle;
  off = ''swaymsg "output * power off"'';
  on = ''swaymsg "output * power on"'';

  # Locks and blanks the screens; any input turns them back on. The first
  # blank happens after 1s, later ones after 10s of no input so the screen
  # doesn't go dark mid-password.
  lock = pkgs.writeShellScript "lock" ''
    pidof hyprlock >/dev/null && exit 0

    ${hyprlock} &
    lock=$!

    # Phase one ends on the first input: the resume handler kills its own
    # swayidle. swayidle double-forks its commands, so $PPID there is not
    # swayidle; instead `exec` makes the inner bash's $$ swayidle's pid.
    # shellcheck disable=SC2016
    "$BASH" -c 'exec ${swayidle} timeout 1 "$1" resume "$2; kill $$"' _ '${off}' '${on}' &
    first=$!
    wait -n "$lock" "$first" || true

    if kill -0 "$lock" 2>/dev/null; then
      ${swayidle} timeout 10 '${off}' resume '${on}' &
      second=$!
      wait "$lock" || true
      kill "$second" 2>/dev/null
    fi

    kill "$first" 2>/dev/null
    ${on}
  '';
in
{
  options.hyprlock.lockCommand = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "${lock}";
    description = "Lock the session and turn the screens off until there is input.";
  };

  options.hyprlock.lockOnLogin = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Start hyprlock together with sway.";
  };

  # plain hyprlock here: the screens stay on at boot
  config.wayland.windowManager.sway.config.startup = lib.mkIf config.hyprlock.lockOnLogin [
    { command = hyprlock; }
  ];

  config.programs.hyprlock = {
    enable = true;
    settings = {
      auth = lib.mkIf fingerprint {
        "pam:enabled" = true;
        "fingerprint:enabled" = true;
      };

      background = {
        monitor = "";
        path = "screenshot";
        blur_passes = 3;
        blur_size = 7;
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      input-field = {
        monitor = "";
        size = "50, 50";
        outline_thickness = 0;
        dots_size = 0.33;
        dots_spacing = 0.15;
        dots_center = true;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0)";
        font_color = "rgba(255, 255, 255, 1.0)";
        fade_on_empty = true;
        placeholder_text = "";
        hide_input = false;
        position = "0, -20";
        halign = "center";
        valign = "center";
      };

      # negative y is below the center
      label = [
        (label "$TIME" 200 100)
      ]
      ++ lib.optional fingerprint (label "$FPRINTPROMPT" (-80) 16)
      ++ [ (label "$LAYOUT" (if fingerprint then -120 else -80) 16) ];
    };
  };
}
