{
  programs.alacritty = {
    enable = true;
    theme = "solarized_light";
    settings = {
      cursor.style = {
        shape = "Block";
        blinking = "Never";
      };

      font = {
        size = 16;
        normal.family = "Monofur Nerd Font";
        bold.family = "Monofur Nerd Font";
        italic.family = "Monofur Nerd Font";
      };

      window = {
        opacity = 0.8;
        padding = {
          x = 0;
          y = 0;
        };
      };

      # Shift+Enter sends ESC+CR (newline in claude-code and friends)
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = builtins.fromJSON ''"\u001B\r"'';
        }
      ];
    };
  };
}
