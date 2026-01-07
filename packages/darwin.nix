{
  pkgs,
  lib,
  ...
}:
let
  darwinPkgs = with pkgs; [
    # nix needs this package to make aliases on macOS
    mkalias
    container

    # darwin apps
    raycast
    maccy
    bruno
    kitty
    alacritty
    alacritty-theme
    utm
    antigravity

    # misc other darwin-specific packages
    yt-dlp
    hugo

    # linux builder
    nixos-rebuild-ng
  ];
in
{
  imports = [
    ./default.nix
  ];

  nixpkgs = lib.mkForce {
    config = {
      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "terraform"
          "raycast"
          "copilot-language-server"
          "github-copilot-cli"
          "crush"
          "amp-cli"
          "antigravity"
        ];
    };
  };

  # environment.systemPackages is required for the system.activationScripts.applicationIndex to work.
  environment.systemPackages = darwinPkgs;

  users.users.taylor = {
    packages = darwinPkgs;
  };
}
