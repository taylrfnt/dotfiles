{
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # other DEs have habits of touching & deleteding cursor themes, so we need to set this manually
        "org/gnome/desktop/interface" = {
          cursor-theme = "Adwaita";
        };
      };
    }
  ];
}
