{
  nix-homebrew = {
    enable = true; # enable homebrew via nix
    enableRosetta = true; # Apple Silicon Only
    user = "taylor"; # User owning the Homebrew prefix
  };

  homebrew = {
    enable = true;
    casks = [
      "firefox@nightly"
      "google-chrome"
      "iina"
      "the-unarchiver"
      "bitwarden"
      "thunderbird"
      "obsidian"
      # "ghostty"
      # make ghostty greedy since we use tip instead of main/stable
      {
        name = "ghostty@tip";
        greedy = true;
      }
      "lulu"
      "oversight"
      "keycastr"
      "obs"
      "audio-hijack"
      "steam"
      "deskpad"
    ];

    brews = [
      "mas" # needs xcode-select (TODO: find automated install)
      "coreutils"
      "telnet"
      "sequin"
      "asciinema"
      # "zig"
    ];

    masApps = {
      "Yoink" = 457622435;
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "Keynote" = 409183694;
      "Parcel" = 639968404;
      "Xcode" = 497799835;
      "Final Cut Pro" = 424389933;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
