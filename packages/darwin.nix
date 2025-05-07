{
  pkgs,
  lib,
  ...
}: let
  darwinPkgs = with pkgs; [
    # nix needs this package to make aliases on macOS
    mkalias

    # misc other darwin-specific packages
    yt-dlp
  ];
  darwinApps = with pkgs; [
    # darwin apps
    raycast
    maccy
    bruno
    kitty
    alacritty
    alacritty-theme
    utm
  ];
in {
  config = {
    nixpkgs = lib.mkForce {
      # nixpkgs = {
      hostPlatform = "aarch64-darwin";
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "terraform"
            "raycast"
          ];
      };
    };
    # environment.systemPackages = darwinApps;
    users.users.taylor = {
      packages = darwinPkgs ++ darwinApps;
    };
  };

  # define a new option to use for aliasing in system/darwin.nix
  options = {
    darwinApps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = darwinApps;
    };
  };
}
