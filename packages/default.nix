{
  pkgs,
  lib,
  ...
}: let
  commonPkgs = with pkgs; [
    # System
    git
    gnupg
    # nvf handles this now...
    # neovim
    dig
    fastfetch
    # Not available on darwin, need to split this out
    # microfetch
    killall
    nh
    xsel
    openssl
    pass

    # Shells
    zsh
    comma
    thefuck
    oh-my-posh
    zsh-vi-mode
    zsh-autosuggestions

    # Tools
    k9s
    lazygit
    yq
    jq
    gh

    # Development
    gnumake
    # nix darwin says this isn't a package.  split this out too
    # libgcc
    go
    nodejs_23
    jdk17
    zig
    rustup
    pandoc

    # File/Navigation
    eza
    fzf
    cheat
    bat
    ripgrep
    wget
    zip
    unzip

    # Performance
    btop
    htop
    # Not available on darwin, need to split this out
    # atop

    # Fonts
    nerd-fonts.commit-mono
    nerd-fonts.jetbrains-mono

    # Cloud
    azure-cli
    kubectl
    kubelogin
    kns
    kubernetes-helm
    helmfile
    skopeo
    cloudfoundry-cli
    terraform

    # Misc
    pipes-rs
  ];
in {
  # allow named unfree packages (we don't want to install something unfree by accident)
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];
  # enable zsh as the default shell
  programs.zsh.enable = true;

  # user configuration
  users.users = {
    taylor = {
      packages = commonPkgs;
      shell = pkgs.zsh;
    };
    # root.packages = commonPkgs;
  };
}
