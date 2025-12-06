{
  lib,
  pkgs,
  ...
}:
let
  wslFiles = {
    # discord-ipc
    ".scripts/discord-ipc" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".scripts/discord-ipc";
      source = ./files/discord-ipc/wsl;
    };
  };
in
{
  imports = [
    ./default.nix
  ];
  hjem.users = {
    taylor = {
      files = lib.mkAfter wslFiles;
      systemd = {
        enable = false;
        # don't need this anymore
        # services = {
        #   "discord-ipc" = {
        #     enable = true;
        #     name = "discord-ipc.service";
        #     description = "Discord RPC for neocrd via WSL";
        #     startLimitIntervalSec = 10;
        #     serviceConfig = {
        #       Type = "simple";
        #       Restart = "on-failure";
        #       RemainAfterExit = "yes";
        #     };
        #     script = "/home/taylor/.scripts/discord-ipc";
        #     wantedBy = [ "default.target" ];
        #     path = [
        #       pkgs.sudo
        #       pkgs.bash
        #       pkgs.socat
        #     ];
        #     reloadIfChanged = true;
        #     restartIfChanged = true;
        #   };
        # };
      };
    };
  };
}
