{
  description = "NixOS + Home Manager (yourusername)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "yourusername";

      mkHost = { hostname, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # Available to both NixOS + HM modules
          specialArgs = { inherit inputs hostname username; };

          modules = [
            ({ lib, ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  gh-dash = prev.gh-dash.overrideAttrs (old: rec {
                    version = "4.23.2";
                    src = prev.fetchFromGitHub {
                      owner = "dlvhdr";
                      repo = "gh-dash";
                      rev = "v${version}";
                      hash = "sha256-C06LPVoE23ITJpMG0x75Djgeup+eb5uYwA8wL7xxvWU=";
                    };
                    vendorHash = "sha256-4AbeoH0l7eIS7d0yyJxM7+woC7Q/FCh0BOJj3d1zyX4=";
                  });
                })
              ];

              # Explicit unfree allowlist — add packages here as needed
              nixpkgs.config.allowUnfreePredicate =
                pkg: builtins.elem (lib.getName pkg) [
                  "claude-code"
                  "obsidian"
                  "protonmail-bridge"
                  "protonmail-desktop"
                  "protonvpn-gui"
                  "davinci-resolve"
                  "lmstudio"
                  "llmster"
                  "tableplus"
                ];
            })

            ./modules/base.nix
            ./hosts/${hostname}/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.${username} = import ./home/${username}.nix;
              home-manager.extraSpecialArgs = { inherit inputs hostname username; };
            }
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        b650e-desktop = mkHost {
          hostname = "b650e-desktop";
          extraModules = [
            ./modules/desktop.nix
            ./modules/hyprland.nix
          ];
        };

        framework = mkHost {
          hostname = "framework";
          extraModules = [
            ./modules/laptop.nix
            ./modules/hyprland.nix
          ];
        };
      };
    };
}
