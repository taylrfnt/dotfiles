{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  darwinPkgs = with pkgs; [
    # nix needs this package to make aliases on macOS
    mkalias
    mas
    container
    devenv

    # darwin apps
    raycast
    maccy
    bruno
    kitty
    alacritty
    alacritty-theme
    utm
    # antigravity
    # vesktop
    macchina

    # misc other darwin-specific packages
    # yt-dlp
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
    packages = darwinPkgs ++ [
      inputs.muzak.packages.${pkgs.stdenv.hostPlatform.system}.muzak
    ];
  };
}
