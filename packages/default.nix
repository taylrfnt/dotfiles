{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  commonPkgs = with pkgs; [
    # System
    git
    jujutsu
    keychain
    bitwarden-cli
    gnupg
    dig
    fastfetch
    killall
    nh
    xsel
    openssl
    passage
    smfh
    gettext
    man
    lsof
    age
    age-plugin-yubikey
    yubikey-manager
    sops
    openssh

    # formatters for nvf
    codespell
    typos
    mbake
    alejandra
    stylua
    gotools
    gofumpt
    deno
    google-java-format
    shellcheck
    shellharden
    black
    sqruff

    # Shells
    zsh
    comma
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
    govulncheck
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
    awscli2
    azure-cli
    kubectl
    kubelogin
    kns
    kubernetes-helm
    helmfile
    skopeo
    cloudfoundry-cli
    terraform
    tailscale

    # AI
    opencode
    # ollama
    tmux
    zellij
    github-copilot-cli
    crush
    # amp-cli

    # Misc
    russ
    pipes-rs
  ];
in
{
  # allow named unfree packages (we don't want to install something unfree by accident)
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
      "copilot-language-server"
      "github-copilot-cli"
      "crush"
      "amp-cli"
    ];
  imports = [
    ./fonts/default.nix
  ];
  users.users.taylor = {
    packages = commonPkgs ++ [
      inputs.nprt.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.amp
    ];
  };
}
