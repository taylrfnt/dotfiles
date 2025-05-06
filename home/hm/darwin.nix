{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  # let Home Manager install & manage itself
  programs.home-manager.enable = true;

  home = {
    username = "taylor";
    homeDirectory = "/Users/taylor";
    stateVersion = "24.11";
    packages = [];
  };

  xdg = {
    enable = true;
    configFile.ghostty = {
      source = mkOutOfStoreSymlink "/Users/taylor/dotfiles/home/hm/files/ghostty/config";
      target = "ghostty/config";
    };
  };

  programs = {
    # import our machine-specific modules first
    zsh = import ./files/zsh/darwin.nix {inherit config pkgs;};
    git = import ./files/git/darwin.nix;
    ## and our generic modules
    oh-my-posh = import ./files/oh-my-posh/default.nix {inherit config pkgs lib;};
    # tmux = import ./files/tmux/efault.nix {inherit config pkgs;};
    # neovim = (import ./files/nvim/default.nix { inherit config pkgs; });
    k9s = import ./files/k9s/default.nix;
    yt-dlp = import ./files/yt-dlp/default.nix;
    # ghostty = import ./files/ghostty/default.nix {inherit config pkgs;};
    alacritty = import ./files/alacritty/default.nix {inherit pkgs;};
    kitty = import ./files/kitty/default.nix {inherit config pkgs;};
  };
}
