# Home-manager config shared by every machine. Per-machine bits live in
# hosts/<name>/home.nix.
{
  imports = [
    ./core.nix
    ./packages.nix
    ./backup.nix
  ];

  # keeps using ~/.config/syncthing (device id, folders) when it exists
  services.syncthing.enable = true;
}
