{ pkgs
, lib
, config
, ...
}:
with lib;
let
  cfg = config.services.chainweb-node;
  downloadCWNSnapshot = pkgs.writeScriptBin "downloadCWNSnapshot" ''
    #!/bin/sh
    set -e

    if [ -f ${cfg.dataDir}/.init-done ]; then
      echo "Chainweb node data directory already initialized, skipping"
      exit 0
    else
      echo "Initializing chainweb node data directory"
      TARGET=${cfg.dataDir}/0
      ${pkgs.coreutils}/bin/mkdir -p $TARGET

      ${pkgs.awscli}/bin/aws s3 cp ${cfg.snapshotUrl} - \
        | ${pkgs.gnutar}/bin/tar -xzvf - -C $TARGET
    fi
  '';
in
{
  options.services.chainweb-node = {
    enable = mkEnableOption "chainweb-node";
    package = mkOption {
      type = types.package;
      description = "The chainweb-node package to use";
      default = pkgs.chainweb-node;
    };
    dataInit = mkOption {
      type = types.path;
      description = "The init script to use for the chainweb-node database";
      default = "${downloadCWNSnapshot}/bin/downloadCWNSnapshot";
    };
    dataDir = mkOption {
      type = types.path;
      description = "The data directory for chainweb-node";
      default = "/var/lib/chainweb-node/${cfg.chainwebVersion}";
    };
    snapshotUrl = mkOption {
      type = types.str;
      description = "The URL of the snapshot to use for initialization";
      default = "s3://kadena-node-db/db-chainweb-node-ubuntu.18.04-latest.tar.gz";
    };
    chainwebVersion = mkOption {
      type = types.str;
      description = "The chainweb version to use";
      default = "mainnet01";
    };
    configYaml = mkOption {
      type = types.path;
      description = "The chainweb-node config file";
      default = ./nixos-module-config.yaml;
    };
    p2pPort = mkOption {
      type = types.int;
      description = "The P2P port to use for chainweb-node";
      default = 1789;
    };
    servicePort = mkOption {
      type = types.int;
      description = "The service port to use for chainweb-node";
      default = 1848;
    };
  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.p2pPort ];

    users.users.chainweb-node = {
      description = "Chainweb Node";
      isSystemUser = true;
      group = "chainweb-node";
    };
    users.groups.chainweb-node = {};

    systemd.services.chainweb-node-init = {
      description = "One-time initialization of chainweb-node from a snapshot";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = cfg.dataInit;
        ExecStartPost = "${pkgs.coreutils}/bin/touch ${cfg.dataDir}/.init-done";
      };
    };

    systemd.services.chainweb-node = {
      description = "Chainweb Node";
      after = [ "network.target" "chainweb-node-init.service" ];
      requires = [ "chainweb-node-init.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${cfg.package}/bin/chainweb-node \
            --chainweb-version ${cfg.chainwebVersion} \
            --database-directory ${cfg.dataDir} \
            --config-file ${cfg.configYaml} \
            --service-port ${toString cfg.servicePort} \
            --p2p-port ${toString cfg.p2pPort}
        '';
        Restart = "always";
        RestartSec = 5;
        LimitNOFILE = 100000;
      };
    };
  };

}