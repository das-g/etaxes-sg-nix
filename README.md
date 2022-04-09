# E-Taxes St.Gallen

This flake provides the eTaxes taxation software packaged for `x86_64-linux` of the Swiss Canton St.Gallen for following years:

* 2021

# Execution

This package requires [nix flakes enabled](https://nixos.wiki/wiki/Flakes) and [is unfree software](https://nixos.wiki/wiki/Flakes#Enable_unfree_software) (althought freely distributable).

```bash
nix shell github:fabianhauser/etaxes-sg-nix#etaxes-ch-sg-2021 --command 'Steuer St.Gallen 2021 nP'
```

