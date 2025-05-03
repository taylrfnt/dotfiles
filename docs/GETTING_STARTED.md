# Getting Started with the wsl-nixos Flake

The following instructions provide a detailed procedure to get your very own
NixOS flake running inside WSL.

This document assumes users are starting from a clean Windows PC with no preset
configurations, so certain sections may be irrelevant to more experienced users.

## Prerequisites

### Installing WSL and a NixOS distribution

To begin, a user needs to first install WSL on their Windows PC.

```pwsh
# In Powershell, run this command to install WSL
wsl --install --no-distribution
```

> [!IMPORTANT]
> After you run this install, you should restart your PC.

Next, the user should download `nixos.wsl` from the
[Releases page](https://github.com/nix-community/NixOS-WSL/releases).

Once the download completes, the user should open the newly downloaded
`nixos.wsl` file. This will begin the NixOS installation in WSL, and progress
will be displayed in a `cmd.exe` window.

After the installation is complete, WSL will launch directly into the installed
NixOS distribution under the default user (`nixos`). It is recommended to run
NixOS system updates before proceeding:

```bash
sudo nix-channel --update
```

6. Restart your WSL after this upgrade:

```bash
sudo reboot
```

## Building the WSL flake

With an updated NixOS system and freshly restarted WSL, a user can now focus on
building the flake that is contained in this repository.

1. Clone this repository to `/etc/nixos`

```bash
cd /etc/nixos && git clone ${REPO_LINK} .
```

2. Modify the default username desired for the system:

> [!TIP]
> The value of `users.users.<name>` is what needs to be updated. It appears in
> two places in this repo: `./packages/default.nix` and `./home/hjem.nix`.

**In `./packages/default.nix`:**

```nix
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];
  programs.zsh.enable = true;
  users.users = {
    taylor = {                  ##### <----- CHANGE "taylor" HERE TO YOUR DESIRED USERNAME
      packages = commonPkgs;
      shell = pkgs.zsh;
    };
    root.packages = commonPkgs;
  };
}
```

**In `./home/hjem.nix`:**

```nix
{ config, pkgs, lib, ... }: {
  enable = true;
  user = "taylor";              ##### <----- CHANGE "taylor" HERE TO YOUR DESIRED USERNAME
  directory = "/home/taylor";   ##### <----- CHANGE "taylor" HERE TO YOUR DESIRED USERNAME
  files = {
```

3. Build the flake configuration and switch into it:

```bash
sudo nixos-rebuild switch --flake --extra-experimental-features 'nix-command flakes'
```

4. Enjoy a pre-configured system that can be reproduced on any WSL system as
   needed!
