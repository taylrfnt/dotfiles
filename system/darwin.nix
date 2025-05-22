{
  pkgs,
  config,
  # options,
  # lib,
  ...
}: {
  nixpkgs = {
    hostPlatform = "aarch64-darwin"; # The platform the configuration will be used on.
    config = {
      allowUnfree = true; # allow unfree app installs
    };
  };

  imports = [
    ./default.nix
  ];

  # user setup
  users.users.taylor = {
    name = "taylor";
    description = "Taylor";
    home = "/Users/taylor";
  };
  system = {
    activationScripts = {
      applicationIndex.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # using MacOs aliases instead of symlinks to allow apps to be indexed by spotlight
          echo "setting up /Applications..." >&2
          applicationsDir="/Applications"
          nixApplicationsDir="$applications/Nix Apps"

          rm -rf "$nixApplicationsDir"
          mkdir -p "$nixApplicationsDir"
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
        '';
    };
  };

  system.stateVersion = 6;
}
