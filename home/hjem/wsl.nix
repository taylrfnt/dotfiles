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
    # discord-ipc svc (UNUSED FOR NOW)
    ".config/systemd/user/discord-ipc.service" = {
      enable = false;
      executable = true;
      clobber = true;
      target = ".config/systemd/user/discord-ipc.service";
      source = ./services/discord-ipc/default;
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
        services = {
          "discord-ipc" = {
            enable = true;
            name = "discord-ipc.service";
            description = "Discord RPC for neocrd via WSL";
            startLimitIntervalSec = 10;
            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RemainAfterExit = "yes";
            };
            script = "/home/taylor/.scripts/discord-ipc";
            wantedBy = [ "default.target" ];
            path = [
              pkgs.sudo
              pkgs.bash
              pkgs.socat
            ];
            reloadIfChanged = true;
            restartIfChanged = true;
          };
        };
      };
    };
  };
}
