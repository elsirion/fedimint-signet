{ config, pkgs, lib, ... }:
let
  nix-bitcoin = import ./templates/nix-bitcoin.nix;
  fedimint-override = pkgs.callPackage
    ({ stdenv, lib, rustPlatform, fetchurl, pkgs, fetchFromGitHub, openssl, pkg-config, perl, clang, jq }:
      rustPlatform.buildRustPackage rec {
        pname = "fedimint";
        version = "master";
        nativeBuildInputs = [ pkg-config perl openssl clang jq pkgs.mold ];
        doCheck = false;
        OPENSSL_DIR = "${pkgs.openssl.dev}";
        OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";  
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        src = builtins.fetchGit {
          url = "https://github.com/elsirion/fedimint";
          ref = "2022-09-fast-ln";
          rev = "734f1414298816ef36ae5ca1299049556276ebd6";
        };
        cargoSha256 = "sha256-gsmdUN9WkhBMIaPTZ75ynijhrqPhYOvHCSttRaTnmWU=";
        meta = with lib; {
          description = "Federated Mint Prototype";
          homepage = "https://github.com/fedimint/fedimint";
          license = licenses.mit;
          maintainers = with maintainers; [ wiredhikari ];
        };
      }) {};
  ip = "104.244.73.68";
in
{
  deployment = {
    targetHost = ip;
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
        address = ip;
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
      package = fedimint-override;
    };

    clightning = {
      enable = true;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
        fedimint-gw = {
          enable = true;
          package = fedimint-override;
        };
      };
      extraConfig = ''
        announce-addr=${ip}:9735
        alias=fm-signet.sirion.io
        large-channels
        experimental-offers
        fee-base=0
        fee-per-satoshi=100
      '';
    };

    rtl = {
      enable = true;
      nodes.clightning.enable = true;
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      proxyTimeout = "1d";
      virtualHosts."fm-signet-gateway.sirion.io" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080/";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
      virtualHosts."fm-signet.sirion.io" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://104.244.73.68:5000";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
        locations."/rtl/" = {
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

