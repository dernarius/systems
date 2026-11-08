{
  # also turns on 32-bit graphics and steam-hardware udev rules
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
}
