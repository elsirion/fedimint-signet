{hostName, hashedPassword, ip, isGateway ? false}:
{ config, pkgs, lib, ... }:
let
  nix-bitcoin = builtins.fetchGit {
    url = "https://github.com/elsirion/nix-bitcoin/";
    ref = "mainnet-v2";
    rev = "b0c14dc43e96c006e0ea6243b3aba3e640c69901";
  };
  fedimint-override = (import
    (
      fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/b4a34015c698c7793d592d66adbab377907a2be8.tar.gz";
        sha256 = "sha256:1qc703yg0babixi6wshn5wm2kgl5y1drcswgszh4xxzbrwkk9sv7";
      }
    )
    { src = fetchTarball {
        url = "https://github.com/fedimint/fedimint/archive/6d83f71e681089a9ca1d2061d74d3a6763dafb2f.tar.gz";
        sha256 = "sha256:1lyp85ypzsbl72jy8a5r8j78vwrlfm1009x0iy5fzkfgp9g59rrz";
      };
    }
  ).defaultNix.packages.x86_64-linux;
  fqdn = "${hostName}.demo.sirion.io";
in
{
  deployment = {
    targetHost = fqdn;
    tags = [ "bitcoin" "mainnet" "fedimint" "demo" ];
  };

  imports = [
    ./templates/frantech.nix
    "${nix-bitcoin}/modules/modules.nix"
  ];

 
  networking = {
    hostName = hostName;
    firewall.allowedTCPPorts = [ 80 443 8173 8333 ];
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
      dbCache = 1000;
      extraConfig = ''
        connect=btc.internal.sirion.io:8333
        rpcauth=bitcoin:a15feeea5b0ec69c22a6ba065816c591$e0822ecb0e7b36c9c77ec8aae3889d6fd3323e8fdac8cbd06cf8f83734130fc5
        fallbackfee=0.00008
      '';
      address = "0.0.0.0";
      listen = true;
      prune = 1000;
    };

    clightning = {
      enable = isGateway;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
        fedimint-gw = {
          enable = isGateway;
          package = fedimint-override.ln-gateway;
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

    fedimint = {
      enable = true;
      package = fedimint-override.fedimintd;
    };

    ttyd = {
      enable = true;
      interface = "lo";
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      proxyTimeout = "1d";
      virtualHosts."admin.${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8172/";
          proxyWebsockets = true;
          extraConfig = "proxy_pass_header Authorization;";
        };
      };
      virtualHosts."${fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8174/";
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

