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
      packages = aarch64LinuxPkgs;
    };
    root.packages = aarch64LinuxPkgs;
  };
}
