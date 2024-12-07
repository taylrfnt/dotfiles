# nix
## What This Is
This directory (and subdirectories within) house the configuration sets for my systems using the [Nix package manager](https://nixos.org/) and
some of the various modules & plugins developed arund it by the maintainers and community.

Nix is a delcarative package manager, so all configuration is defined in the various `*.nix` files.  Read more about it at their official site above.

## Directory Structure
### Home Manager (`home`)
The `home` directory houses configurations for various tools (Nix calls them "packages") that can be installed across architectures/OSes.  The configurations within the `home` directory are sourced by a Nix module called [Home Manager](https://github.com/nix-community/home-manager).

The important thing to remember for the package conifgurations in `home` are that they are for packages managed by the Home Manager module, and should not have any OS-specific configuratios within them, so they should be portable across all architectures.

### OS/Arch Specific
The remaining folders in this repository are dedicated to OS-specific configuration sets that cannot be applied across systems with different
architectures/OSes.  As new architectures/OSes are configured using Nix, they will be added to this repository under their own directories.

For now, only a `darwin` (MacOS) system configuration set has been created, and is available in the `darwin` directory.

## Getting Started
Each directory (with the exception of `home`, given it is a cross-platform configuration set that in sourced during a nix build) has its own set of
instructions to get started using the configuration set it contains in a `README.md`.  Refer to the specific platform's directory & README file to
build out your system with Nix!
