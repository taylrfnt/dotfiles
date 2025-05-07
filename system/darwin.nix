{
  pkgs,
  config,
  lib,
  ...
}: {
  # user setup
  users.users.taylor = {
    name = "taylor";
    description = "Taylor";
    home = "/Users/taylor";
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
    activationScripts = {
      # using MacOs aliases instead of symlinks to allow apps to be indexed by spotlight
      applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          echo "cleaning up /Applications/Nix Apps..." >&2
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
      # automatically catch (most) new prefs without login/restart
      postUserActivation.text = ''
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
    };

    #MacOS system configuration
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

      screencapture = {
        type = "png";
        target = "clipboard";
      };
    };
  };
}
