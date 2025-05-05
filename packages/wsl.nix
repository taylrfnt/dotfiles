{
  pkgs,
  lib,
  ...
}: let
  wslPkgs = with pkgs; [
    # System
    microfetch

    # Development
    libgcc

    # Performance
    atop
  ];
in {
  # enable zsh as the default shell
  programs.zsh.enable = true;

  # user configuration
  users.users = {
    taylor = {
      packages = wslPkgs;
      shell = pkgs.zsh;
    };
    root.packages = wslPkgs;
  };
}
