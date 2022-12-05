{ hostName, ip }:
{ config, pkgs, lib, ... }:
let
  nix-bitcoin = builtins.fetchGit {
    url = "https://github.com/elsirion/nix-bitcoin/";
    ref = "adopting";
    rev = "d2b60c461db2e1f7f7595828dbe3363f7d91f882";
  };
  fedimint-override = (import
    (
      fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/b4a34015c698c7793d592d66adbab377907a2be8.tar.gz";
        sha256 = "sha256:1qc703yg0babixi6wshn5wm2kgl5y1drcswgszh4xxzbrwkk9sv7";
      }
    )
    { src = fetchTarball {
        url = "https://github.com/fedimint/fedimint/archive/d13040431263ff7064726b8d736862da2ba96de3.tar.gz";
        sha256 = "sha256:1v9j2j1s097srxlz1lim61hzmxzwqwwrax043qhfzgq7g0ac81sz";
      };
    }
  ).defaultNix.packages.x86_64-linux;
  fqdn = "${hostName}.regtest.sirion.io";
in
{
  deployment = {
    targetHost = fqdn;
    tags = [ "bitcoin" "regtest" "fedimint" ];
  };

  imports = [
    ./templates/frantech.nix
    "${nix-bitcoin}/modules/modules.nix"
  ];

  environment.systemPackages = [
    fedimint-override.fedimint-cli fedimint-override.gateway-cli
  ];
 
  networking = {
    hostName = hostName;
    firewall.allowedTCPPorts = [ 80 443 8333 9735 ];
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
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3sJOyg8iYMV57DD3KtohfbY/FI4iDrVGn3KWxjFYc3VDX38vVRid/64f72bYHz3lWBuRvzBaOmGqJukVzLzQ0SfMqgll4cIIFGz3ScnQsQSdDwrzpvxc7GcrFQQ2bFcWgs3zb5Yqc8AmXj5crJNlBBT8hPkrdxL3j8FRC8n9+hdDGDyaYyJZiO+ufIfYKrDxQM01XkjrL8PCoiCdyGZEqg+OaYhRIn456uNIXCa6/z0vxETZDqu2nRZfdKwkUuJTCpblkSh1wnQuWUxuca5K21oe/OTv5u6Y4ZtsF1hTPqFMDfcflyq6xodl7xEfVQSAMrHXel6qNzjl1PxQDi4YKOeAuQjZS0o0YbDCysQAhviDiRmn8gnQb8siZNmuTibJkV8kWo1TO5FVkxiHefWeCb8ntFNM6a/UGfVjggl0UR8DugAubWHatZ7LOC9s8YMavmSXLg73IOAokZcLexsSDz9gKa6MNGBm8bt7KgFElU/aL6IwCXfNvyq7XXhi65OWRbNT3SFT2dAtxHDhdh0NhlDo9PDecJfl003VJ9I+zddyflOXzAE1/Xi8uBfeWPSGu9H2LBX6ik0ydjSDgkidRe0hRkRzIotb3fHN6GK5b+kGbPclASH17C/lmEPAjFCHVYFwcaDqmCHLwll5D1ji7Lcw/4uG6qSn1DU8GJf7E4w== oscarlafarga@mac-studio.lan"
        ];
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
      extraConfig = ''
        connect=alpha.regtest.sirion.io:8333
        connect=bravo.regtest.sirion.io:8333
        rpcauth=bitcoin:a15feeea5b0ec69c22a6ba065816c591$e0822ecb0e7b36c9c77ec8aae3889d6fd3323e8fdac8cbd06cf8f83734130fc5
        fallbackfee=0.00008
      '';
      address = "0.0.0.0";
      listen = true;
    };

    clightning = {
      enable = true;
      address = "0.0.0.0";
      plugins = {
        summary.enable = true;
        fedimint-gw = {
          enable = true;
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
      virtualHosts."gw.${fqdn}" = {
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
          proxyPass = "http://127.0.0.1:5001";
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

