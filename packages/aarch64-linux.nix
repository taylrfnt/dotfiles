{
  pkgs,
  # lib,
  ...
}: let
  aarch64LinuxPkgs = with pkgs; [
    # System
    microfetch
    spice
    spice-vdagent

    # Terminals
    ghostty
    alacritty
    alacritty-theme
    kitty
    kitty-themes

    # Development
    libgcc

    # Performance
    atop
  ];
in {
  imports = [
    ./default.nix
  ];
  # enable zsh as the default shell
  programs.zsh.enable = true;

  # user configuration
  users.users = {
    taylor = {
      packages = aarch64LinuxPkgs;
    };
  };
}
