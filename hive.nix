let
  demo = import ./machines/demo.nix;
in {
  meta = {
    nixpkgs = <nixpkgs>;
  };

  defaults = { pkgs, ... }: {
    deployment = {
      targetUser = "elsirion";
    };
    
    environment.systemPackages = with pkgs; [
      vim wget curl tmux htop jq
    ];

    users = {
      mutableUsers = false;
      users.elsirion = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ./id_rsa.pub)
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9H+Ls/IS8yOTvUHS6e5h/EXnn5V3mg23TlqcSExiUk mail@justinmoon.com" # TODO: create separate account
        ];
        hashedPassword = "$6$.FhPAweWIPA4A$5JrQXS/TAvscjjaPj1b2OhPPeb0VJiKKFQk00.FogspSp3HLXkMAnC8mPO92TRwBJePPXXObQbl.FQ6GVNQWI/";
      };
    };

    time.timeZone = "UTC";

    nix.trustedUsers = [ "root" "@wheel" ];

    security.sudo.wheelNeedsPassword = false;

    services.openssh.enable = true;
  };

  fm-signet = import ./machines/fm-signet.nix;
  sigpay = import ./machines/sigpay.nix;
  demo-alpha = demo {
    hostName = "alpha";
    hashedPassword = "$y$j9T$ZYjQO/dOFQWxQUi6M5F7A.$5XxFjTXBmBs.sdhymYwqgCoyruprLWXWtpupWFprWIB";
    isGateway = true;
  };
  demo-bravo = demo {
    hostName = "bravo";
    hashedPassword = "$y$j9T$Ll2b8mxiSYorjv5Vcw1Ws1$tp/1bCG3oucnGkEFdxnU2maKwFhZ91EfoG40U1SLzQ1";
  };
  demo-charlie = demo {
    hostName = "charlie";
    hashedPassword = "$y$j9T$rceqB9AC.PxAcMupBXvO.0$I8QMvFLhxx9Enp5tRugTWZixPsWuRgYtr2TonwoBug1";
  };
  demo-delta = demo {
    hostName = "delta";
    hashedPassword = "$y$j9T$ljLCyZEIca1rp24ImkwPL1$CYvDmGDAigIm/4gQ.S8Ci6UU86WzHuysQZ1mcO8U15A";
  };
}

