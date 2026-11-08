{
  description = "NixOS + home-manager configs for gnocchi (laptop), blahaj (desktop) and a rescue installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = { inherit inputs pkgs-unstable; };

      # `home` is the home-manager config for stk: the full one on real
      # machines, just the desktop core on the installer
      mkHost =
        hostModule: home:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./hosts/common
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                # existing hand-written dotfiles get moved aside instead of blocking activation
                backupFileExtension = "hm-bak";
                extraSpecialArgs = specialArgs;
                users.stk.imports = [ home ];
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        gnocchi = mkHost ./hosts/gnocchi ./home;
        blahaj = mkHost ./hosts/blahaj ./home;
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
