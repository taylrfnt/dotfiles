{
  pkgs,
  lib,
  ...
}: let
  commonPkgs = with pkgs; [
    # System
    git
    keychain
    gnupg
    # nvf handles this now...
    # neovim
    dig
    fastfetch
    killall
    nh
    xsel
    openssl
    pass
    smfh
    gettext

    # Shells
    zsh
    comma
    # replace thefuck w pay-respects
    # thefuck
    # pay-respects
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
    go
    # nodejs_24
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
  imports = [
    ./fonts/default.nix
  ];
  users.users.taylor = {
    packages = commonPkgs;
  };
}
