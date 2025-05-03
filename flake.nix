{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    hjem,
    nvf,
    ...
  } @ inputs: {
    pkgs.config.allowUnfree = true;
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
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
            hjem.users.taylor = ./home/hjem.nix;
          }
          # add our nvf configurations
          nvf.nixosModules.default
          ./modules/nvf/nvf.nix
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
    };
  };
}
