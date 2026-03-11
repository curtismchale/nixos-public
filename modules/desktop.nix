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

  services.hardware.openrgb.enable = true;

  # Intel Arc B580 — OpenCL, VA-API, and Quick Sync
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver    # VA-API (iHD) — hardware video decode/encode
    vpl-gpu-rt            # oneVPL / Quick Sync Video
    intel-compute-runtime # OpenCL + Level Zero
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Fan monitoring & control — nct6775 Super I/O chip on ASUS B650E
  boot.kernelModules = [ "nct6775" ];
  programs.coolercontrol.enable = true;
  environment.systemPackages = [ pkgs.lm_sensors ];
}
