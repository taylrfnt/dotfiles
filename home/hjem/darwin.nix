{pkgs, ...}: {
  enable = true;
  user = "taylor";
  directory = "/Users/taylor";
  files = {
    # zsh
    ".zshrc" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".zshrc";
      # source = ./files/zsh/default.zshrc;
      text = ''
        ${builtins.readFile ../files/zsh/default.zshrc}
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      '';
    };

    # oh-my-posh
    ".config/oh-my-posh/zen.toml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/oh-my-posh/zen.toml";
      source = ../files/oh-my-posh/default.toml;
    };

    # k9s
    ".config/k9s/config.yaml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/k9s/config.yaml";
      source = ../files/k9s/default.yaml;
    };
    ".config/k9s/skins/catppuccin-mocha-transparent.yaml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/k9s/skins/catppuccin-mocha-transparent.yaml";
      source = ../files/k9s/skins/catppuccin-mocha-transparent.yaml;
    };

    # cheat
    ".config/cheat/conf.yml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/cheat/conf.yml";
      source = ../files/cheat/default.yml;
    };

    # git
    ".gitconfig" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".gitconfig";
      source = ../files/git/default.gitconfig;
    };

    # ghostty
    ".config/ghostty/config" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/ghostty/config";
      source = ../files/ghostty/default-config;
    };
  };
}
