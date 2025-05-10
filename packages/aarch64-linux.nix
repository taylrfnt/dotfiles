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
  programs = {
    # enable dconf management
    dconf.enable = true;
    # enable zsh as the default shell
    zsh.enable = true;
    # Install firefox.
    firefox.enable = true;
  };

  # user configuration
  users.users = {
    taylor = {
      packages = aarch64LinuxPkgs;
      shell = pkgs.zsh;
    };
  };
}
