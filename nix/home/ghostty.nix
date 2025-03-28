{ config, pkgs, ... }:

{
  enable = false;
  ## See https://ghostty.org/docs/config for official docs & option
  ## sets or run `ghostty +list-configuration --default`
  enableZshIntegration = true;
  settings = {
    ## Appearance
    theme = "catppuccin-mocha"; 
    window-colorspace = "display-p3";
    split-divider-color = "#585b70";
    macos-titlebar-proxy-icon = "hidden";
    title = " ";
    window-height = 35;
    window-width = 150;
    
    ## Font
    font-family = "CommitMono Nerd Font";
    font-feature = "+cv07";
    font-size = 16;
    font-thicken = true;
    adjust-cell-height = "15%";
    
    ## Misc
    focus-follows-mouse = true;
    mouse-hide-while-typing = true;
    copy-on-select = "clipboard";
    confirm-close-surface = false;
    quit-after-last-window-closed = true;
    window-save-state = "default";

    keybind = [
      "alt+right=unbind"
      "alt+left=unbind"
      "global:super+alt+ctrl+shift+t=toggle_quick_terminal"
    ];
  };

}
