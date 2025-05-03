{
  pkgs,
  lib,
  inputs,
  ...
}: {
  nix = {
    #package = pkgs.lix;

    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) inputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;

    settings = {
      nix-path = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;
      flake-registry = "";

      download-buffer-size = 500000000;
      experimental-features = ["nix-command" "flakes"];
      # enable community cache for modules (working behind the proxy breaks lots of builds)
      substituters = ["http://nix-community.cachix.org"];
      trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    };
  };
  environment = {
    variables = {
      EDITOR = "nvim";
    };
  };
}
