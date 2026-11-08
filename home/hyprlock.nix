# Fingerprint unlock is turned on wherever the system runs fprintd (gnocchi).
# greetd logs straight into sway, so hyprlock doubles as the login screen.
{
  config,
  lib,
  osConfig,
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
in
{
  options.hyprlock.lockOnLogin = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Start hyprlock together with sway.";
  };

  config.wayland.windowManager.sway.config.startup = lib.mkIf config.hyprlock.lockOnLogin [
    { command = lib.getExe config.programs.hyprlock.package; }
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
