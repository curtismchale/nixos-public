{ pkgs, ... }:

{
  # XWayland — keeps X11 app compatibility under Wayland
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # AMD Ryzen 7040 Series iGPU — VA-API via Mesa radeonsi (included by default, no extra packages needed)

  # Backlight control — user must be in video group for brightnessctl
  # to work without sudo (used in Hyprland XF86MonBrightness keybinds)
  users.users.curtismchale.extraGroups = [ "video" ];

  # Battery and power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Fingerprint reader
  services.fprintd.enable = true;
  security.pam.services.sddm.fprintAuth = true;


  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
