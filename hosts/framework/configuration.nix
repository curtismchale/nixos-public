{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/laptop.nix
    ../../modules/hyprland.nix
  ];

  networking.hostName = "framework";
  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pinned to 6.19.x — do not use linuxPackages_latest
  boot.kernelPackages = pkgs.linuxPackages_6_19;
}
