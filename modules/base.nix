{ config, pkgs, lib, ... }:

{
  # Networking
  networking.networkmanager.enable = true;

  # Time / locale
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow unfree packages (1Password, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Strongly recommended for your flake-based workflow
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Generation pruning — keep at most 20, then delete anything older than 7 days
  # Runs daily BEFORE garbage collection so pruned generations become collectible.
  # Uses nix-env on the system profile directly (not nix-collect-garbage, which
  # would delete ALL generations older than 7d with no minimum-keep guarantee).
  systemd.services.nix-gc-generations = {
    description = "Prune old NixOS generations";
    before = [ "nix-gc.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Keep the 20 most recent system generations, delete the rest
      ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system \
        --delete-generations +20
    '';
  };
  systemd.timers.nix-gc-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Garbage collection — collect unreferenced store paths daily
  # (generation pruning above determines what becomes unreferenced)
  nix.gc = {
    automatic = true;
    dates = "daily";
  };

  # Auto-optimise the store (hardlink identical files) on every build
  nix.settings.auto-optimise-store = true;
  nix.settings.trusted-users = [ "root" "curtismchale" ];

  # Allow unprivileged processes to bind to ports 80+ (needed for devenv Caddy)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # Keep only the 20 most recent boot entries in systemd-boot menu
  boot.loader.systemd-boot.configurationLimit = 20;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  programs.zsh.enable = true;

  # User (shared; keep packages out if you’ll use Home Manager)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "curtismchale" ];
  };

  users.users.curtismchale = {
    isNormalUser = true;
    description = "curtismchale";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "_1password" ];
    shell = pkgs.zsh;
  };

      programs.nix-ld.enable = true;

  # Start minimal; add libs if Claude complains about missing ones
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
    openssl
  ];

  services.openssh.enable = true;

  # Baseline for all machines
  programs.firefox.enable = true;

  # gaming
  programs.steam.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.syncthing = {
    enable = true;
    user = "curtismchale";
    dataDir = "/home/curtismchale";
    configDir = "/home/curtismchale/.config/syncthing";
    openDefaultPorts = true;
  };

  # mDNS — required to resolve .local hostnames (e.g. glacier.local)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Glacier NAS — SMB automount at ~/Glacier
  # Credentials must be set up manually; see CLAUDE.md for instructions.
  environment.systemPackages = [ pkgs.cifs-utils ];

  systemd.tmpfiles.rules = [
    "d /home/curtismchale/Glacier 0755 curtismchale users -"
  ];

  fileSystems."/home/curtismchale/Glacier" = {
    device = "//glacier.local/glacier-shared";
    fsType = "cifs";
    options = [
      "credentials=/home/curtismchale/.smbcredentials"
      "uid=1000"
      "gid=100"
      "vers=3.1.1"
      "_netdev"
      "noauto"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=300"
    ];
  };
}
