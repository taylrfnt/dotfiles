{
  imports = [
    ./default.nix
  ];

  files = {
    # ghostty
    ".config/ghostty/config" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/ghostty/config";
      source = ./files/ghostty/default-config;
    };
  };
}
