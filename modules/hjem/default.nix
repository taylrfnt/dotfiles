{ pkgs, ... }:
let
  commonFiles = {
    # zsh
    ".zshrc" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".zshrc";
      # source = ./files/zsh/default.zshrc;
      text = ''
        ${builtins.readFile ./files/zsh/default.zshrc}
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      '';
    };

    # ghostty
    ".config/ghostty/config" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/ghostty/config";
      source = ./files/ghostty/default-config;
    };

    # oh-my-posh
    ".config/oh-my-posh/zen.toml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/oh-my-posh/zen.toml";
      source = ./files/oh-my-posh/default.toml;
    };
    ".config/oh-my-posh/zen-embedded.toml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/oh-my-posh/zen-embedded.toml";
      source = ./files/oh-my-posh/embedded.toml;
    };

    # k9s
    ".config/k9s/config.yaml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/k9s/config.yaml";
      source = ./files/k9s/default.yaml;
    };
    ".config/k9s/skins/catppuccin-mocha-transparent.yaml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/k9s/skins/catppuccin-mocha-transparent.yaml";
      source = ./files/k9s/skins/catppuccin-mocha-transparent.yaml;
    };

    # cheat
    ".config/cheat/conf.yml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/cheat/conf.yml";
      source = ./files/cheat/default.yml;
    };

    # git
    ".gitconfig" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".gitconfig";
      source = ./files/git/default.gitconfig;
    };

    # amp
    ".config/amp" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/amp";
      source = ./files/amp;
    };
  };
in
{
  hjem = {
    linker = pkgs.smfh;
    users = {
      taylor = {
        enable = true;
        files = commonFiles;
      };
    };
  };
}
