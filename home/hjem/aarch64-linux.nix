{
  imports = [
    ./default.nix
  ];

  directory = "/home/taylor";
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
