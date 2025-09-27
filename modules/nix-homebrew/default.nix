{
  nix-homebrew = {
    enable = true; # enable homebrew via nix
    enableRosetta = true; # Apple Silicon Only
    user = "taylor"; # User owning the Homebrew prefix
  };
}
