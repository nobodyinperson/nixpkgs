# nix-build '<nixpkgs/nixos>' -I nixpkgs=. -I nixos-config=./vm.nix -A config.system.build.vm && find -maxdepth 1 -iname '*.qcow2' -delete && result/bin/run*vm
{ pkgs, config, ... }: {
  system.stateVersion = "25.05";
  users.users.me = {
    isNormalUser = true;
    initialPassword = "asdf";
  };
  services.getty.autologinUser = "me";
  environment.systemPackages = with pkgs;
    let
      log = writeShellApplication rec {
        name = "log";
        text = "echo I am named '${name}'";
      };
      logg = writeShellApplication rec {
        name = "logg";
        text = "echo I am named '${name}'";
      };
    in [ log logg ];
  programs.bash.shellInit = "(set -x;log;logg)";
}
