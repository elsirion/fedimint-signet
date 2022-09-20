{ config, pkgs, lib, ... }:
let
  nix-bitcoin = import ./templates/nix-bitcoin.nix;
  faucet-override = import (builtins.fetchGit {
    url = "https://github.com/elsirion/fedimint_helper";
    ref = "2022-09-improve-help-text";
    rev = "2fa8e6ed27f5b2aa8bc07d84be93d6c172c0d1ca";
  });
in
{
  deployment = {
    targetHost = "107.189.12.188";
    tags = [ "bitcoin" "lightning" "signet" "btcpay" ];
  };

  imports = [
    ./templates/frantech.nix
    "${nix-bitcoin}/modules/modules.nix"
  ];


  networking = {
    hostName = "signet-btcpay";
    firewall.allowedTCPPorts = [ 80 443 9735 ];
    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "107.189.12.188";
        prefixLength = 24;
      }];
    };
    defaultGateway = "107.189.12.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  security = {
    acme =  {
      email = "w6082wbk@anonaddy.me";
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

    clightning = {
      enable = true;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
      };
      extraConfig = ''
        alias=sigpay.sirion.io
        large-channels
        experimental-offers
        fee-base=0
        fee-per-satoshi=100
      '';
    };

    btcpayserver = {
      enable = true;
      lightningBackend = "clightning";
    };

    fedimint-faucet = {
      enable = true;
      connect = ''
        {"members":[[0,"wss://fm-signet.sirion.io:443"]],"max_evil":0}
      '';
      package = pkgs.callPackage faucet-override {};
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      proxyTimeout = "1d";
      virtualHosts."sigpay.sirion.io" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:23000";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
      virtualHosts."faucet.sirion.io" = {
        enableACME = true;
        enableSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
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

