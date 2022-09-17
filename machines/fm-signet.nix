{ config, pkgs, lib, ... }:
let
  nix-bitcoin = import ./templates/nix-bitcoin.nix;
in
{
  deployment = {
    targetHost = "104.244.73.68";
    tags = [ "bitcoin" "lightning" "signet" "fedimint" ];
  };

  imports = [
    ./templates/frantech.nix
    "${nix-bitcoin}/modules/modules.nix"
  ];

 
  networking = {
    hostName = "fm-signet";
    firewall.allowedTCPPorts = [ 80 443 5000 9735 ];
    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "104.244.73.68";
        prefixLength = 24;
      }];
    };
    defaultGateway = "104.244.73.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  security = {
    acme =  {
      defaults.email = "w6082wbk@anonaddy.me";
      acceptTerms = true;
    };
  };

  nix-bitcoin.operator = {
    enable = true;
    name = "elsirion";
  };

  nix-bitcoin = {
    generateSecrets = true;
    onionServices = {
      bitcoind.enable = true;
    };
    nodeinfo.enable = true;
  };

  services = {
    bitcoind = {
      enable = true;
      signet = true;
      disablewallet = true;
      dbCache = 2000;
    };

    fedimint = {
      enable = true;
    };

    clightning = {
      enable = true;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
        fedimint-gw = {
          enable = true;
        };
      };
      extraConfig = ''
        alias=fm-signet.sirion.io
        large-channels
        experimental-offers
        fee-base=0
        fee-per-satoshi=100
      '';
    };


    nginx = {
      enable = true;
      recommendedProxySettings = true;
      proxyTimeout = "1d";
      virtualHosts."fm-signet-gateway.sirion.io" = {
        enableACME = true;
        addSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080/";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
      virtualHosts."fm-signet.sirion.io" = {
        enableACME = true;
        addSSL = true;
        locations."/" = {
          proxyPass = "http://104.244.73.68:5000";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "21.11"; # Did you read the comment?

  # The nix-bitcoin release version that your config is compatible with.
  # When upgrading to a backwards-incompatible release, nix-bitcoin will display an
  # an error and provide hints for migrating your config to the new release.
  nix-bitcoin.configVersion = "0.0.70";

  system.extraDependencies = [ nix-bitcoin ];
}

