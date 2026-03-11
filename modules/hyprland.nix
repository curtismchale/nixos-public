{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # Needed for screen sharing, portals, file pickers under Wayland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      Hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # Useful Wayland utilities (optional)
  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    bluetuith #bluetooth
    networkmanager # nmtui command
  ];
}
