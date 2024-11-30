{
  description = "Zenful nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs = {
        hostPlatform = "aarch64-darwin"; # The platform the configuration will be used on.
        config = {
          allowUnfree = true; # allow unfree app installs
        };
      };

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.neovim
          pkgs.tmux
          pkgs.stow
          pkgs.pass
	        pkgs.oh-my-posh
	        pkgs.pyenv
          pkgs.zsh-autosuggestions
          pkgs.mkalias
          pkgs.yt-dlp
          pkgs.lua-language-server
          pkgs.gopls
          pkgs.marksman
          pkgs.gofumpt
          pkgs.prettierd
          pkgs.yaml-language-server
          pkgs.yamlfix
          pkgs.yamlfmt
          pkgs.shellcheck
          pkgs.uncrustify
          pkgs.bash-language-server
          pkgs.jq
          pkgs.stylua
          pkgs.zsh-autosuggestions
          pkgs.maccy
          pkgs.raycast
        ];

      # user setup
      users.users.taylorfont = {
        name = "taylorfont";
        description = "Taylor F. User";
        home = "/Users/taylorfont";
      };

      # Configure Homebrew
      homebrew = {
        enable = true;
        casks = [
          "firefox@nightly"
          "iina"
          "the-unarchiver"
          "bitwarden"
          "kitty"
          "obsidian"
        ];
        brews = [
          "openjdk@17"
          "openjdk@21"
          "mas"
        ];
        masApps = {
          "Final Cut Pro" = 424389933;
          "Yoink" = 457622435;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      # Install fonts
      fonts = {
        packages = with pkgs; [
          # more fonts via `nix repl -f nerd-fonts.`
          nerd-fonts.jetbrains-mono
        ];
      };

      system = {
        # Set Git commit hash for darwin-version.
        configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        stateVersion = 5;

        # darwin config
        defaults = {
          #:: TODO :: Add login items for maccy ( not yet supported by nix-darwin )
          ".GlobalPreferences"."com.apple.sound.beep.sound" = "/System/Library/Sounds/Blow.aiff";
          dock = {
            autohide = true;
            autohide-delay = 0.0; # no delay for auto-hide/show
            orientation = "left";
            mineffect = "scale";
            minimize-to-application = true;
            magnification = false;
            show-recents = false; # hide recent apps from dock
            # set dock apps
            #persistent-apps = [
            #  "/System/Applications/Launchpad.app"
            #  "${pkgs.firefox}/Applications/Firefox Nightly.app"
            #  "/System/Applications/Messages.app"
            #  "/System/Applications/FaceTime.app"
            #  "/System/Applications/Mail.app"
            #  "/System/Applications/Photos.app"
            #  "/System/Applications/TV.app"
            #  "/System/Applications/Music.app"
            #  "/System/Applications/News.app"
            #  "/System/Applications/App Store.app"
            #  "${pkgs.obsidian}/Applications/Obsidian.app"
            #  "${pkgs.kitty}/Applications/kitty.app"
            #  "${pkgs.iina}/Applications/IINA.app"
            #  "${pkgs.Yoink}/Applications/Yoink.app"
            #];
          };
          finder.FXPreferredViewStyle = "clmv"; # column view
          loginwindow.GuestEnabled = false; # no guest logins
          NSGlobalDomain.AppleICUForce24HourTime = true; # enable 24hr time
          menuExtraClock.Show24Hour = true; # show 24 hr clock in menu/login
          screencapture.type = "png"; # make screenshots png files
          ## :: TODO :: set custom browser default ( CustomPrefs? )
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

      # Enable alternative shell support in nix-darwin.
      programs.zsh.enable = true; # default shell on catalina
      # programs.fish.enable = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#amaterasu
    darwinConfigurations."amaterasu" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # enable homebrew via nix
            enableRosetta = true; # Apple Silicon Only
            user = "taylorfont"; # User owning the Homebrew prefix
          };
        }
      ];
    };
  };
}

