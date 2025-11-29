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
    # opencode
    ".config/opnecode/opencode.json" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/opencode/opencode.json";
      source = ./files/opencode/default.json;
    };
  };
}
