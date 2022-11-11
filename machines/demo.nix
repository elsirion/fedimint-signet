{hostName, hashedPassword, isGateway ? false}:
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
          url = "https://github.com/fedimint/fedimint";
          ref = "hcpp";
          rev = "10d408e20e99b33e9cca102bf104324cee893134";
        };
        cargoSha256 = "sha256-rFkzIvW11DmDEn3QpcAUS7owqU8iTnjX0uTBGUlvtyc=";
        meta = with lib; {
          description = "Federated Mint Prototype";
          homepage = "https://github.com/fedimint/fedimint";
          license = licenses.mit;
          maintainers = with maintainers; [ wiredhikari ];
        };
      }) {};
  fqdn = "${hostName}.demo.sirion.io";
in
{
  deployment = {
    targetHost = fqdn;
    tags = [ "bitcoin" "regtest" "fedimint" "demo" ];
  };

  imports = [
    ./templates/frantech.nix
    "${nix-bitcoin}/modules/modules.nix"
  ];

 
  networking = {
    hostName = hostName;
    firewall.allowedTCPPorts = [ 80 443 ];
    interfaces.ens3.useDHCP = true;
  };

  users = {
      mutableUsers = false;
      users.operator = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ../id_rsa.pub)
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9H+Ls/IS8yOTvUHS6e5h/EXnn5V3mg23TlqcSExiUk mail@justinmoon.com" # TODO: create separate account
        ];
        hashedPassword = hashedPassword;
      };
    };

  security = {
    acme =  {
      defaults.email = "w6082wbk@anonaddy.me";
      acceptTerms = true;
    };
  };

  nix-bitcoin.operator = {
    enable = true;
    name = "operator";
  };

  nix-bitcoin = {
    generateSecrets = true;
    nodeinfo.enable = true;
  };

  services = {
    bitcoind = {
      enable = true;
      regtest = true;
      dbCache = 1000;
    };

    fedimint = {
      enable = true;
      package = fedimint-override;
    };

    clightning = {
      enable = isGateway;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
        fedimint-gw = {
          enable = isGateway;
          package = fedimint-override;
        };
      };
      extraConfig = ''
        alias=${fqdn}
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
      virtualHosts."gateway.demo.sirion.io" = lib.mkIf isGateway {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080/";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
      virtualHosts."${fqdn}" = {
        enableACME = true;
        forceSSL = true;
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

