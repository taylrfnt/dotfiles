{
  pkgs,
  # lib,
  ...
}:
let
  wslPkgs = with pkgs; [
    # System
    microfetch
    socat

    # Development
    libgcc

    # Performance
    atop
  ];
in
{
  imports = [
    ./default.nix
  ];
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
