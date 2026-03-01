{ config, options, pkgs, lib, ... }:
let
  cfg = config.services.koffan;
  inherit (lib) mkOption mkPackageOption mkEnableOption mkIf types;
  defaultUser = "koffan";
  defaultGroup = "koffan";
in {
  options.services.koffan = {
    enable = mkEnableOption "koffan shopping list";
    package = mkPackageOption pkgs "koffan" { };
    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User account under which koffan runs";
    };
    group = mkOption {
      type = types.str;
      default = defaultGroup;
      description = "Group under which koffan runs";
    };
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for the koffan webinterface";
    };
    database.path = mkOption {
      type = types.path;
      default = "/var/lib/koffan/koffan.db";
      description = "Path to the koffan database";
    };
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = lib.literalExpression ''
        "/etc/koffan-environment.env"
        config.age.secrets."koffan-environment".path
      '';
      description = ''
        Environment file for specifying additional settings or secrets such as APP_PASSWORD and API_TOKEN
      '';
    };
    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf (types.nullOr types.str);
      };
      default = { APP_ENV = "production"; };
      description = "Environment variables passed to the koffan service";
      apply = value: options.services.koffan.settings.default // value;
      example = lib.literalExpression ''
        {
          DEFAULT_LANG = "de";
          DISABLE_AUTH = "true"; # to auto-login
          APP_PASSWORD = "asdf"; # for testing only!
        }
      '';
    };
  };
  config = mkIf cfg.enable {
    users = {
      users = mkIf (cfg.user == defaultUser) {
        ${defaultUser} = {
          description = "koffan service user";
          inherit (cfg) group;
          isSystemUser = true;
        };
      };
      groups = mkIf (cfg.group == defaultGroup) { ${defaultGroup} = { }; };
    };
    systemd.services.koffan = {
      environment = (lib.filterAttrs (_: v: v != null) cfg.settings) // {
        PORT = toString cfg.port;
        DB_PATH = cfg.database.path;
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.getExe cfg.package;
        EnvironmentFile = cfg.environmentFile;
        Restart = "on-failure";
        StateDirectory = "koffan";
        # Hardening (mostly copied from homebox nixos module)
        LimitNOFILE = "1048576";
        PrivateTmp = true;
        PrivateDevices = true;
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RemoveIPC = true;
        SystemCallArchitectures = "native";
        NoNewPrivileges = true;
        SystemCallFilter = [ "@system-service" "~@privileged" ];
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        UMask = "0077";
      };
      wantedBy = [ "multi-user.target" ];
    };
    meta.maintainers = with lib.maintainers; [ nobodyinperson ];
  };
}
