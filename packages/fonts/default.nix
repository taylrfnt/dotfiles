{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      # Normal Fonts
      commit-mono
      # Nerd Fonts
      # nerd-fonts.commit-mono
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
    # fontDir.enable = true;
  };
}
