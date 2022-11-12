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
    hashedPassword = "$6$hzIRKLk8LIKxm0PT$XHEkBRfYy45AW7evbA8lrdMq64mcBwsKjZ6tHzbJgHFaYNgTvoAR6GdQj.XhYmguXGscrTaJLMlAeDG9KrAyt.";
    isGateway = true;
  };
  demo-bravo = demo {
    hostName = "bravo";
    hashedPassword = "$6$gZIBwt.fHujNo0xY$dLqq.0ae8Pfxe8qYYrKIPC6sK8Jl04AllEcSgLm6fTMiAXzE.cacN4AwEeOsMMHXeHJIrSrvYtIDAVbBy/YDC0";
  };
  demo-charlie = demo {
    hostName = "charlie";
    hashedPassword = "$6$eKwsHabyXiTNQCfn$RM3IYTxOuJW8Zlqoa8bi03CqYP0wFqXCg0c6uN6twUWOunJploYk43WWnvDfC0XeHRht1NmBSMUZOw.zcG5Be.";
  };
  demo-delta = demo {
    hostName = "delta";
    hashedPassword = "$6$k6QJK/nyCbKEhAU.$ZEDh6dP1t7dC0kJTmWZwlumQRrIFvMcJFxb1r1hNo0..dXq3ftfzcNn2/DtvbaKqMqju6ErxK3LRIyrSImOJu0";
  };
}

