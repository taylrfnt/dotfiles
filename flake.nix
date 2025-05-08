{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # system things (WSL, darwin)
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = {
    self,
    nixpkgs,
    hjem,
    home-manager,
    nvf,
    nixos-wsl,
    nix-darwin,
    nix-homebrew,
    ...
  } @ inputs: {
    pkgs.config.allowUnfree = true;
    nixosConfigurations = {
      # Inari - my WSL system
      "inari" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [
          # add our system configurations
          ./system/default.nix
          # add our packages
          ./packages/default.nix
          # source our home configs (hjem)
          hjem.nixosModules.default
          {
            hjem.users.taylor = ./home/hjem/default.nix;
          }
          # add our nvf configurations
          nvf.nixosModules.default
          ./modules/nvf/wsl.nix
          # source wsl configurations
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.11";
            wsl = {
              enable = true;
              defaultUser = "taylor";
              interop = {
                includePath = true;
                register = true;
              };
            };
          }
        ];
      };
      # Fujin - my NixOS VM
      "fujin" = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "aarch64-linux";
        modules = [
          # add hardware configurations
          ./hardware/aarch64-linux.nix
          # add our system configurations
          ./system/aarch64-linux.nix
          # add our packages
          ./packages/aarch64-linux.nix
          # source our home configs (hjem)
          hjem.nixosModules.default
          {
            hjem.users.taylor = ./home/hjem/aarch64-linux.nix;
          }
          # add our nvf configurations
          nvf.nixosModules.default
          ./modules/nvf/default.nix
        ];
      };
    };
    # Amaterasu - my darwin system
    darwinConfigurations = {
      "amaterasu" = nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./system/default.nix
          ./system/darwin.nix
          # nvf
          nvf.nixosModules.default
          ./modules/nvf/default.nix
          # nix-homebrew
          nix-homebrew.darwinModules.nix-homebrew
          ./modules/nix-homebrew/default.nix
          # packages
          ./packages/default.nix
          ./packages/darwin.nix
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.taylor = import ./home/hm/darwin.nix;
          }
        ];
      };
    };
  };
}
