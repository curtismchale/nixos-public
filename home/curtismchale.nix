{ hostname, ... }:

{
  home.username = "curtismchale";
  home.homeDirectory = "/home/curtismchale";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  imports = [
    ./profiles/common.nix
    (if hostname == "framework"
     then ./profiles/laptop.nix
     else ./profiles/desktop.nix)
  ];
}
