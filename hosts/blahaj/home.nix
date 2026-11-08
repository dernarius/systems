{ pkgs, ... }:

{
  imports = [ ./audio-toggle.nix ];

  home.packages = with pkgs; [
    amdgpu_top
    piper
    v4l2-relayd
  ];

  backup = {
    encryptKey = "B64C29A6";
    exclude = [ ];
  };

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "default";
        profile.outputs = [
          {
            criteria = "AOC U32G3X XYDPAJA000474";
            status = "disable";
          }
          {
            criteria = "Dell Inc. DELL U3225QE 3QZQKF4";
            mode = "3840x2160@120Hz";
            position = "0,0";
          }
          {
            criteria = "DP-2";
            mode = "3840x2160@120Hz";
            position = "3840,0";
          }
          {
            criteria = "HDMI-A-1";
            status = "disable";
          }
        ];
      }
    ];
  };

  wayland.windowManager.sway.config = {
    # the TV; tv-mode.nix drives it through gamescope instead
    output.HDMI-A-1.disable = "";

    input."1267:12866:VEN_04F3:00_04F3:3242_Touchpad" = {
      natural_scroll = "enabled";
      scroll_factor = "0.5";
      tap = "enabled";
      tap_button_map = "lrm";
    };

    keybindings = {
      "Mod1+Shift+u" = "output DP-1 power toggle; output DP-2 power toggle";
      "Mod1+Shift+y" = "exec systemctl suspend";
    };
  };
}
