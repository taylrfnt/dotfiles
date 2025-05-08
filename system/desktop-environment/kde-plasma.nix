{pkgs, ...}: {
  # Enable the KDE Plasma Desktop Environment.
  # services.displayManager.sddm = {
  # enable = true;
  # package = pkgs.kdePackages.sddm;
  # theme =
  # };
  services.desktopManager.plasma6.enable = true;
}
