{
  description = "Zenful nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager, ... }: {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#<flake-name>
    darwinConfigurations."base" = nix-darwin.lib.darwinSystem {
      modules = [
        ./base/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylor"; # User owning the Homebrew prefix
          };
        }
        home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.taylor = import ./home.nix;
        }
      ];
    };

    darwinConfigurations."game" = nix-darwin.lib.darwinSystem {
      modules = [
        ./game/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylor"; # User owning the Homebrew prefix
          };
        }
        home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.taylor = import ./home.nix;
        }
      ];
    };

    darwinConfigurations."edit" = nix-darwin.lib.darwinSystem {
      modules = [
        ./edit/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylor"; # User owning the Homebrew prefix
          };
        }
        home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.taylor = import ./home.nix;
        }
      ];
    };

    darwinConfigurations."typeset" = nix-darwin.lib.darwinSystem {
      modules = [
        ./typeset/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylor"; # User owning the Homebrew prefix
          };
        }
        home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.taylor = import ./home.nix;
        }
      ];
    };

    darwinConfigurations."dev" = nix-darwin.lib.darwinSystem {
      modules = [
        ./dev/configuration.nix
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylor"; # User owning the Homebrew prefix
          };
        }
        home-manager.darwinModules.home-manager
        {
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.taylor = import ./home.nix;
        }
      ];
    };
  };

}

