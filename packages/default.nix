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
    microfetch
    killall
    nh
    xsel
    openssl

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
    libgcc
    go_1_23
    go
    nodejs_23
    jdk17
    zig
    rustup
    cargo

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
    atop

    # Fonts
    nerd-fonts.commit-mono

    # Cloud
    azure-cli
    kubectl
    kubelogin
    kns
    helm
    helmfile
    skopeo
    cloudfoundry-cli
    terraform
  ];
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];
  programs.zsh.enable = true;
  users.users = {
    taylor = {
      packages = commonPkgs;
      shell = pkgs.zsh;
    };
    root.packages = commonPkgs;
  };
}
