# swaybar fed by i3status, prefixed with the active keyboard layout
{ config, pkgs, ... }:

let
  i3status = config.programs.i3status.package;
  statusCommand = pkgs.writeShellScript "sway-status" ''
    ${i3status}/bin/i3status | while :
    do
      read line
      lang="$(swaymsg -rt get_inputs | ${pkgs.jq}/bin/jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name ' | head -n 1)"
      echo "$lang $line" || exit 1
    done
  '';
in
{
  programs.i3status = {
    enable = true;
    enableDefault = false;
    general = {
      interval = 1;
      colors = true;
      separator = " ";
    };
    modules."tztime local" = {
      position = 10;
      settings.format = "%Y-%m-%d %H:%M:%S";
    };
  };

  wayland.windowManager.sway.config.bars = [
    {
      # from PATH, i.e. swayfx's swaybar
      command = "swaybar";
      inherit (config.wayland.windowManager.sway.config) fonts;
      position = "bottom";
      statusCommand = "${statusCommand}";
      trayOutput = "*";
      colors = {
        statusline = "#ffffffff";
        background = "#00000000";
        focusedWorkspace = {
          border = "#00000000";
          background = "#99999999";
          text = "#ffffffff";
        };
        activeWorkspace = {
          border = "#00000000";
          background = "#99999999";
          text = "#ffffffff";
        };
        inactiveWorkspace = {
          border = "#00000000";
          background = "#00000000";
          text = "#ffffffff";
        };
        urgentWorkspace = {
          border = "#00000000";
          background = "#dc322fcc";
          text = "#ffffffff";
        };
      };
    }
  ];
}
