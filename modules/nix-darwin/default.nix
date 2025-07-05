{pkgs, ...}: {
  #MacOS system configuration
  # homebrew installs
  homebrew = {
    enable = true;
    casks = [
      "firefox@nightly"
      "google-chrome"
      "zen"
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
      "orbstack"
      "audio-hijack"
      "steam"
      "deskpad"
      "protonvpn"
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

  # login items
  launchd.user.agents = {
    raycast = {
      serviceConfig.ProgramArguments = ["${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast"];
      # [ "${pkgs-master.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast" ];
      serviceConfig.RunAtLoad = true;
    };

    maccy = {
      serviceConfig.ProgramArguments = ["${pkgs.maccy}/Applications/Maccy.app/Contents/MacOS/Maccy"];
      serviceConfig.RunAtLoad = true;
    };

    oversight = {
      serviceConfig.ProgramArguments = ["/Applications/OverSight.app/Contents/MacOS/OverSight"];
      serviceConfig.RunAtLoad = true;
    };

    lulu = {
      serviceConfig.ProgramArguments = ["/Applications/LuLu.app/Contents/MacOS/LuLu"];
      serviceConfig.RunAtLoad = true;
    };

    yoink = {
      serviceConfig.ProgramArguments = ["/Applications/Yoink.app/Contents/MacOS/Yoink"];
      serviceConfig.RunAtLoad = true;
    };
  };
  system = {
    primaryUser = "taylor";

    activationScripts = {
      # automatically catch (most) new prefs without login/restart
      postActivation.text = ''
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
    };

    defaults = {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 1.0;
        "com.apple.sound.beep.sound" = "/System/Library/Sounds/Blow.aiff";
      };
      dock = {
        autohide = true;
        autohide-delay = 0.0; # no delay for auto-hide/show
        orientation = "bottom";
        mineffect = "scale";
        minimize-to-application = true;
        magnification = false;
        show-recents = false; # hide recent apps from dock
        persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/Applications/Firefox Nightly.app"
          "/Applications/Zen.app/"
          "/Applications/Google Chrome.app/"
          "/Applications/Bitwarden.app"
          "/System/Applications/Messages.app"
          "/System/Applications/FaceTime.app"
          "/Applications/Thunderbird.app"
          "/System/Applications/Photos.app"
          "/System/Applications/TV.app"
          "/System/Applications/Music.app"
          "/System/Applications/News.app"
          "${pkgs.vesktop}/Applications/Vesktop.app"
          "/Applications/Obsidian.app/"
          "/Applications/IINA.app/"
          "/Applications/Ghostty.app"
          "/System/Applications/App Store.app"
          "/System/Applications/System Settings.app"
          "/System/Applications/iPhone Mirroring.app"
        ];
        persistent-others = [
          "/Users/taylor/Downloads"
        ];
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        _FXSortFoldersFirst = true;
      };

      loginwindow = {
        GuestEnabled = false;
        LoginwindowText = " ";
        SHOWFULLNAME = false;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowSeconds = true;
      };

      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        "com.apple.swipescrolldirection" = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSWindowShouldDragOnGesture = true;
      };

      WindowManager = {
        AutoHide = true;
        GloballyEnabled = true;
      };

      screencapture = {
        type = "png";
        target = "clipboard";
      };
    };
  };
  power = {
    restartAfterFreeze = true;
    restartAfterPowerFailure = true;
  };
}
