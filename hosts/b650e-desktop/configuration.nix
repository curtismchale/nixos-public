{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/hyprland.nix
  ];

  networking.hostName = "b650e-desktop";
  system.stateVersion = "25.11";

  # Bootloader (usually shared, but safe to keep host-local)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel — pinned to 6.19.x series (not _latest) to avoid auto-bumping
  # to 6.20.0 on flake update. See README "Kernel" section for details.
  boot.kernelPackages = pkgs.linuxPackages_6_19;

  # custom hosts for your sites
  # The format below goes inside the network hosts block 
  # "127.0.01" = ["domain.one", "domain.two"]; 
  networking.hosts = {
    };

  # Disk encryption mapping (machine-specific UUID)
  boot.initrd.luks.devices."luks-13d6600a-c71f-4a8c-8986-8f5e93554502".device =
    "/dev/disk/by-uuid/13d6600a-c71f-4a8c-8986-8f5e93554502";
}
