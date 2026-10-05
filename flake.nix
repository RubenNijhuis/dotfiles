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
    # experimenting across macOS and Linux. Browser profile data stays local
    # and is never part of this flake.
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
        ./nix/home/vscode.nix
      ];
      mkHome =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs username; };
          inherit modules;
        };
    in
    rec {
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
                ./nix/profiles/leisure.nix
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

      # Force the actual host configurations, not only package/devShell outputs.
      # Cross-platform evaluation uses --no-build; build the current host alone.
      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          homes = nixpkgs.lib.filterAttrs (
            _: home: home.pkgs.stdenv.hostPlatform.system == system
          ) homeConfigurations;
          editorHome =
            if system == "aarch64-darwin" then
              darwinConfigurations.Rubens-MacBook-Pro.config.home-manager.users.${username}
            else
              (builtins.head (builtins.attrValues homes)).config;
        in
        nixpkgs.lib.mapAttrs (_: home: home.activationPackage) homes
        // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
          macos = darwinConfigurations.Rubens-MacBook-Pro.system;
        }
        // {
          neovim =
            pkgs.runCommand "neovim-smoke"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.neovim
                  pkgs.gitMinimal
                  pkgs.lua-language-server
                ];
              }
              ''
                bash ${inputs.self}/tests/test-neovim.sh ${editorHome.home.file.".config/nvim".source} --smoke
                touch $out
              '';
        }
      );

      packages = forAllSystems (system: {
        nixfmt-tree = (pkgsFor system).nixfmt-tree;
      });

      # Opt-in environments: the same locked maintenance tools locally/in CI,
      # plus a narrow Node 22 compatibility shell for older projects. New
      # projects should pin their own shell, not grow the global profile.
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          yarn = pkgs.yarn.override { nodejs = pkgs.nodejs_22; };
        in
        {
          maintenance = pkgs.mkShell {
            packages = with pkgs; [
              bashInteractive
              biome
              git
              gnumake
              python3
              shellcheck
              shellharden
            ];
          };
          node22 = pkgs.mkShell {
            packages = [
              pkgs.nodejs_22
              yarn
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);

      templates.node = {
        path = ./templates/nix-project;
        description = "Pinned Node/pnpm environment for a new code project";
      };
    };
}
