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
  users.users.taylor = {
    packages = darwinPkgs;
  };
}
