{
  nixpkgs = {
    hostPlatform = "aarch64-darwin"; # The platform the configuration will be used on.
    config = {
      allowUnfree = true; # allow unfree app installs
    };
  };
}
