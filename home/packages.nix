# Everything beyond the desktop core: apps, dev tools, games.
{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  lazy = pkgs.callPackage ./lazy.nix { stateDir = "${config.xdg.stateHome}/lazy"; };
in
{
  home.packages =
    (with pkgs; [
      # fonts for documents
      corefonts
      vista-fonts

      # system utils
      acpica-tools
      cryptsetup
      docker-compose
      duplicity
      fastfetch
      imagemagick
      ncdu
      shpool
      parted
      pinentry-all
      powertop
      udiskie
      udisks
      unzip
      usbutils
      v4l-utils

      # audio
      alsa-tools
      alsa-utils
      pasystray
      pnmixer
      pavucontrol

      # utils
      curl
      fd
      gnumake
      jq
      nomacs
      sacad
      tesseract
      tree
      wget
      zellij

      # applications
      abcde
      alacritty-theme
      blender
      calibre
      deluge
      discord
      feishin
      freecad
      gimp
      inkscape
      keepassxc
      obs-studio
      onlyoffice-desktopeditors
      solaar
      thunderbird
      vivaldi
      vlc

      # languages
      bun
      gcc
      go
      gopls
      lua-language-server
      nixd
      nixfmt
      python314
      rust-analyzer
      stylua
      tree-sitter
      ty
      uv

      # gaming
      clpeak
      gamescope
      mangohud
      mesa-demos
      openttd
      pcsx2
      steam-rom-manager
      steam-run
      vulkan-tools
      wineWow64Packages.stable
      winetricks
      lunar-client

      # unfree, so never in the binary cache: built on first launch instead
      (lazy {
        pkg = modrinth-app;
        desktopItem = {
          desktopName = "Modrinth App";
          comment = "Modrinth's game launcher";
          icon = "share/icons/hicolor/128x128/apps/ModrinthApp.png";
          categories = [
            "Game"
            "ActionGame"
            "AdventureGame"
            "Simulation"
          ];
          keywords = [
            "game"
            "minecraft"
            "mc"
          ];
          mimeTypes = [
            "application/x-modrinth-modpack+zip"
            "x-scheme-handler/modrinth"
          ];
          startupWMClass = "ModrinthApp";
          startupNotify = true;
        };
      })
    ])
    ++ (with pkgs-unstable; [
      boilr
      claude-code
      lutris
    ]);

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
  };
}
