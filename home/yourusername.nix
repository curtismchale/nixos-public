{ hostname, ... }:

{
  home.username = "yourusername";
  home.homeDirectory = "/home/yourusername";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  imports = [
    ./profiles/common.nix
    (if hostname == "framework"
     then ./profiles/laptop.nix
     else ./profiles/desktop.nix)
  ];
}
