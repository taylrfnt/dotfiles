{
  imports = [
    ./default.nix
  ];

  networking.hostName = "inari";

  # user setup
  users.users.taylor = {
    name = "taylor";
    description = "Taylor";
    home = "/home/taylor";
  };
}
