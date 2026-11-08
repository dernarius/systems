{ config, ... }:

let
  inherit (config.lib.formats.rasi) mkLiteral;
in
{
  programs.rofi = {
    enable = true;

    extraConfig = {
      timeout = {
        action = "kb-cancel";
        delay = 0;
      };
      filebrowser = {
        directories-first = true;
        sorting-method = "name";
      };
    };

    # solarized light, translucent
    theme = {
      "*" = {
        font = "Monofur Nerd Font 14";

        background = mkLiteral "#fdf6e3aa";
        foreground = mkLiteral "#586e75";

        black = mkLiteral "#073642";
        red = mkLiteral "#dc322f";
        green = mkLiteral "#859900";
        yellow = mkLiteral "#b58900";
        blue = mkLiteral "#268bd2";
        magenta = mkLiteral "#d33682";
        cyan = mkLiteral "#2aa198";
        white = mkLiteral "#073642";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@foreground";
        accent-color = mkLiteral "@yellow";
      };

      window = {
        background-color = mkLiteral "@background";
        location = mkLiteral "center";
        width = mkLiteral "960px";
        height = mkLiteral "480px";
        padding = mkLiteral "30px";
        border = mkLiteral "0px";
      };

      inputbar = {
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "12px";
        children = map mkLiteral [
          "prompt"
          "entry"
        ];
      };

      "prompt, entry, element-text, element-icon".vertical-align = mkLiteral "0.5";

      prompt.text-color = mkLiteral "@black";

      listview = {
        lines = 8;
        columns = 1;
        fixed-height = false;
      };

      element = {
        padding = mkLiteral "8px";
        spacing = mkLiteral "8px";
      };
      "element normal urgent".text-color = mkLiteral "@red";
      "element normal active".text-color = mkLiteral "@blue";
      "element selected".text-color = mkLiteral "@background";
      "element selected normal".background-color = mkLiteral "@foreground";
      "element selected urgent".background-color = mkLiteral "@background";
      "element selected active".background-color = mkLiteral "@background";

      element-icon.size = mkLiteral "0.75em";
      element-text.text-color = mkLiteral "inherit";
    };
  };
}
