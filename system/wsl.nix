{
  pkgs,
  config,
  # options,
  # lib,
  ...
}:
{
  imports = [
    ./default.nix
  ];

  # user setup
  users.users.taylor = {
    name = "taylor";
    description = "Taylor";
    home = "/home/taylor";
  };
  # systemd = {
  #   services = {
  #     "discord-ipc" = {
  #       enable = true;
  #       wantedBy = [ "default.target" ];
  #       description = "Discord IPC Service for neocord in WSL";
  #       serviceConfig = {
  #         Restart = "on-failure";
  #       };
  #       script = ''
  #         socat UNIX-LISTEN:/var/run/discord-ipc-0,user=taylor,group=users,umask=007,fork \
  #           EXEC:"/mnt/c/Users/taylr/go/bin/wsl-relay.exe --close-pipe --pipe-closes --pipe //./pipe/discord-ipc-0"
  #       '';
  #       path = [
  #         pkgs.socat
  #       ];
  #       reloadIfChanged = true;
  #       restartIfChanged = true;
  #     };
  #   };
  # };
}
