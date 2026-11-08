{ pkgs, ... }:

{
  home.packages = [ pkgs.brightnessctl ];

  backup = {
    encryptKey = "F1D15517";
    exclude = [ ];
  };

  programs.i3status.modules."battery 0" = {
    position = 0;
    settings.format = "%status %percentage (%consumption)";
  };

  services.batsignal.enable = true;

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "desktop";
        profile.outputs = [
          {
            criteria = "eDP-1";
            position = "0,0";
          }
          {
            criteria = "Dell Inc. DELL U3225QE 3QZQKF4";
            position = "1920,0";
          }
          {
            criteria = "AOC U32G3X XYDPAJA000474";
            position = "5760,0";
          }
        ];
      }
    ];
  };

  wayland.windowManager.sway.config = {
    output = {
      eDP-1.position = "0 0";
    };

    input = {
      "type:touchpad" = {
        natural_scroll = "enabled";
        scroll_factor = "0.75";
        tap = "enabled";
        tap_button_map = "lrm";
        click_method = "button_areas";
        middle_emulation = "enabled";
      };
      "2:10:TPPS/2_Elan_TrackPoint" = {
        accel_profile = "flat";
        pointer_accel = "0";
        scroll_factor = "0.25";
      };
    };

    keybindings = {
      "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
      "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
    };
  };

  wayland.windowManager.sway.extraConfig = ''
    bindgesture swipe:3:left workspace next
    bindgesture swipe:3:right workspace prev
  '';
}
