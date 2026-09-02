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

    # Zen Twilight is an intentional, separately profiled preview channel for
    # experimenting across macOS and Linux. The stable macOS release remains
    # installed independently as a rollback path.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
      # Keep host composition static and reviewable. The shell-based machine
      # profile selects automations only; it never changes reproducible Nix
      # imports at evaluation time.
      baseHomeModules = [
        ./nix/home/common.nix
        ./nix/profiles/core.nix
      ];
      developerHomeModules = baseHomeModules ++ [ ./nix/profiles/developer.nix ];
      desktopHomeModules = developerHomeModules ++ [
        ./nix/profiles/browser.nix
        ./nix/profiles/desktop-core.nix
      ];
      mkHome =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs username; };
          inherit modules;
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
              imports = desktopHomeModules ++ [
                ./nix/profiles/macos-apps.nix
                ./nix/profiles/writing.nix
              ];
            };
          }
        ];
      };

      homeConfigurations = {
        rubennijhuis-windows-wsl = mkHome "x86_64-linux" developerHomeModules;
        rubennijhuis-linux-desktop = mkHome "x86_64-linux" (
          desktopHomeModules
          ++ [
            ./nix/profiles/writing.nix
            ./nix/profiles/gaming.nix
          ]
        );
        rubennijhuis-linux-aarch64 = mkHome "aarch64-linux" (
          baseHomeModules
          ++ [
            ./nix/profiles/browser.nix
          ]
        );
      };

      packages = forAllSystems (system: {
        nixfmt-tree = (pkgsFor system).nixfmt-tree;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
