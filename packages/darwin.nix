{
  pkgs,
  lib,
  ...
}: let
  darwinPkgs = with pkgs; [
    # nix needs this package to make aliases on macOS
    mkalias

    # darwin apps
    raycast
    maccy
    bruno
    kitty
    alacritty
    alacritty-theme
    utm

    # misc other darwin-specific packages
    yt-dlp
  ];
in {
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
  users.users.taylor = {
    packages = darwinPkgs;
  };
}
