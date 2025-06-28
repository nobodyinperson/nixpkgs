# nix-build '<nixpkgs/nixos>' -I nixpkgs=. -I nixos-config=./vm.nix -A config.system.build.vm && find -maxdepth 1 -iname '*.qcow2' -delete && result/bin/run*vm
# But it doesn't work. The new builder is never used 🙄 Why!?
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
  # Fix system path
  system.path = pkgs.buildEnv {
    name = "system-path-with-log-allowed";
    builder = (let
      builder = pkgs.replaceVars
        ./pkgs/build-support/buildenv/builder-with-log-allowed.pl {
          inherit (builtins) storeDir;
        };
    in builtins.trace builder builder);
    paths = config.environment.systemPackages;
    inherit (config.environment) pathsToLink extraOutputsToInstall;
    ignoreCollisions = true;
    postBuild = ''
      # Remove wrapped binaries, they shouldn't be accessible via PATH.
      find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete

      if [ -x $out/bin/glib-compile-schemas -a -w $out/share/glib-2.0/schemas ]; then
          $out/bin/glib-compile-schemas $out/share/glib-2.0/schemas
      fi

      ${config.environment.extraSetup}
    '';
  };
}
