# Fedimint signet

This repository contains the nix deployment code for my [fedimint](https://github.com/fedimint/fedimint/) signet instance. It uses [colmena](https://github.com/zhaofengli/colmena) for orchestration.

## Testing changes

To test if your nix code is valid run `colmena build` or `colmena build --on <server name>` to only test one server.

## Deploying

Please make sure to always push changes when deploying them. Run the following to deploy:

```
colmena apply
```