{
  description = "Ruben's cross-platform personal development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      ...
    }:
    let
      username = "rubennijhuis";
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHome =
        system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs username; };
          modules = [ ./nix/home/common.nix ] ++ extraModules;
        };
    in
    {
      darwinConfigurations.Rubens-MacBook-Pro = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs username; };
        modules = [
          ./nix/hosts/Rubens-MacBook-Pro.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = {
              imports = [
                ./nix/home/common.nix
                ./nix/profiles/core.nix
                ./nix/profiles/desktop-core.nix
                ./nix/profiles/macos-apps.nix
                ./nix/profiles/design.nix
                ./nix/profiles/media.nix
                ./nix/profiles/sync.nix
              ];
            };
          }
        ];
      };

      homeConfigurations = {
        rubennijhuis-windows-wsl = mkHome "x86_64-linux" [
          ./nix/profiles/core.nix
        ];
        rubennijhuis-linux-desktop = mkHome "x86_64-linux" [
          ./nix/profiles/core.nix
          ./nix/profiles/desktop-core.nix
          ./nix/profiles/gaming.nix
          ./nix/profiles/sync.nix
        ];
        rubennijhuis-linux-aarch64 = mkHome "aarch64-linux" [
          ./nix/profiles/core.nix
        ];
      };

      packages = forAllSystems (system: {
        nixfmt-tree = (pkgsFor system).nixfmt-tree;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
