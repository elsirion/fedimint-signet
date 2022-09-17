{
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
}

