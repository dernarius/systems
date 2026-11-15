# The desktop core: sway and everything it needs to feel like home. This is
# all the installer gets; real machines add ./packages.nix and ./backup.nix.
{ pkgs, ... }:

{
  imports = [
    ./sway.nix
    ./status.nix
    ./alacritty.nix
    ./rofi.nix
    ./hyprlock.nix
  ];

  home.username = "stk";
  home.homeDirectory = "/home/stk";

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.monofur
    just
  ];

  services.mako.enable = true;
  services.polkit-gnome.enable = true;

  home.stateVersion = "26.05";
}
