let
  demo = import ./machines/demo.nix;
  regtest = import ./machines/regtest.nix;
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
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3aMTG1hzTO0+v5e7hlh6kkOkSCQbReJMZC/w8bFR/JwHUxuPtw1zNIvQuzofoqv/AeMBZFTzmNbN3IVsWRO3UoVkE6BIHqggzqf1jjI78hnmGqktKn1SltxZ/j0JkO++5YWU/ItkifB5czPnMgWcQl7860jNeNK/OiPSCCpiMvdu6c7UEjFr4O1JrACRAavohQE4dcHQ1LyZ99RzCMICSS0OFoarxJkxFg9+TOrq2jmUv4Z4faPT5WMdwXJ3dTmaGBlT1JddWR+BxDeeXWHx0p90T2oWmROnBJx/d5KGReXSFQzOj6irI3J9k5x1sGBlBLq/n4L8fBgnW+g0Ih+uMm8w5iocCuOsHxyDZIViziMLe2LQPIUovgpgTgKMuGxPYeUMxTOjHDqzdAfHU8yTZKVwS1KPzYVxbQaLK9kNUZtjsKQbkLC3aFr85GfJEhBO+6tzaN6ia491aSna4l+lI6Y7iHDJ/Ed918GBygln5uLpp8glDcxWRAQCaXmADamc= deployserver"
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
    ip = "45.61.184.243";
  };
  demo-bravo = demo {
    hostName = "bravo";
    hashedPassword = "$6$gZIBwt.fHujNo0xY$dLqq.0ae8Pfxe8qYYrKIPC6sK8Jl04AllEcSgLm6fTMiAXzE.cacN4AwEeOsMMHXeHJIrSrvYtIDAVbBy/YDC0";
    ip = "45.61.186.63";
  };
  demo-charlie = demo {
    hostName = "charlie";
    hashedPassword = "$6$eKwsHabyXiTNQCfn$RM3IYTxOuJW8Zlqoa8bi03CqYP0wFqXCg0c6uN6twUWOunJploYk43WWnvDfC0XeHRht1NmBSMUZOw.zcG5Be.";
    ip = "45.61.186.157";
  };
  demo-delta = demo {
    hostName = "delta";
    hashedPassword = "$6$k6QJK/nyCbKEhAU.$ZEDh6dP1t7dC0kJTmWZwlumQRrIFvMcJFxb1r1hNo0..dXq3ftfzcNn2/DtvbaKqMqju6ErxK3LRIyrSImOJu0";
    ip = "45.61.185.226";
  };

  regtest-alpha = regtest {
    hostName = "alpha";
    ip = "45.61.188.218";
  };
  regtest-bravo = regtest {
    hostName = "bravo";
    ip = "45.61.186.165";
  };
}

