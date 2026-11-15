{
  description = "NixOS + home-manager configs for gnocchi (laptop), blahaj (desktop) and girlboss (headless NAS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # declarative partitioning (girlboss, installed with nixos-anywhere)
    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secure Boot; track release tags, not main
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
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

      mkHost =
        modules:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [ ./hosts/common ] ++ modules;
        };

      # graphical machines: desktop module + home-manager for stk, with `home`
      # as the home-manager config
      mkDesktop =
        hostModule: home:
        mkHost [
          ./hosts/common/desktop.nix
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
    in
    {
      nixosConfigurations = {
        gnocchi = mkDesktop ./hosts/gnocchi ./home;
        blahaj = mkDesktop ./hosts/blahaj ./home;
        # headless, no home-manager
        girlboss = mkHost [ ./hosts/girlboss ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
