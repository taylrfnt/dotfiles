{ config, pkgs, ... }:

{
  nixpkgs = {
    hostPlatform = "aarch64-darwin"; # The platform the configuration will be used on.
    config = {
      allowUnfree = true; # allow unfree app installs
    };
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.neovim
    pkgs.tmux
    pkgs.git
    pkgs.stow
    pkgs.gh
    pkgs.pass
    pkgs.gnupg
    pkgs.oh-my-posh
    pkgs.zsh-vi-mode
    pkgs.mkalias
    pkgs.zsh-autosuggestions
    pkgs.maccy
    pkgs.raycast
    pkgs.zsh
    pkgs.fish
  ];

  # Install fonts
  fonts = {
    packages = [
      # more fonts via `nix repl -f nerd-fonts.`
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.noto
      pkgs.nerd-fonts.commit-mono
    ];
  };

  # source homebrew
  # Configure Homebrew
  homebrew = {
    enable = true;
    casks = [
      "firefox@nightly"
      "google-chrome"
      "iina"
      "the-unarchiver"
      "bitwarden"
      "obsidian"
      "ghostty"
      "lulu"
      "oversight"
      "keycastr"
    ];
    brews = [
      "openjdk@17"
      "openjdk@21"
      "coreutils"
    ];
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  # enable fish
  programs.fish. enable = true;

  # user setup
  users = {
    users.taylorfont = {
      name = "taylorfont";
      description = "Taylor Font";
      home = "/Users/taylorfont";
      shell = pkgs.fish;
    };
  };

  environment.variables = {
    # see https://github.com/ghostty-org/ghostty/discussions/2832
    XDG_DATA_DIRS = ["/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration"];
    EDITOR = "nvim";
  };


  system = {
    # Set Git commit hash for darwin-version.
    #configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 5;

    #MacOS system configuration
    defaults = {
      ".GlobalPreferences"."com.apple.sound.beep.sound" = "/System/Library/Sounds/Blow.aiff";
      dock = {
        autohide = true;
        autohide-delay = 0.0; # no delay for auto-hide/show
        orientation = "bottom";
        mineffect = "scale";
        minimize-to-application = true;
        magnification = false;
        show-recents = false; # hide recent apps from dock
      };
      finder.FXPreferredViewStyle = "clmv"; # column view
      loginwindow.GuestEnabled = false; # no guest logins
      NSGlobalDomain.AppleICUForce24HourTime = true; # enable 24hr time
      menuExtraClock.Show24Hour = true; # show 24 hr clock in menu/login
      screencapture = {
        type = "png"; # make screenshots png files
        target = "clipboard";
      };
    };

    activationScripts = {
      # automatically catch (most) new prefs without login/restart
      postUserActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
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
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
    };
  };

}

