# proton-cachy.nix

An automatically updated Nix flake for the latest stable
[Proton-CachyOS](https://github.com/CachyOS/proton-cachyos) Steam Linux Runtime
release. The conservative upstream `x86_64` binary is the default for
`x86_64-linux`, with the optimized `x86_64_v3` binary available as an explicit
alternative for compatible CPUs.

## Use with NixOS

Add the flake input and its NixOS module:

```nix
{
  inputs.proton-cachy.url = "github:Zariel/proton-cachy.nix";

  outputs = { nixpkgs, proton-cachy, ... }@inputs: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        proton-cachy.nixosModules.default
        ({ ... }: {
          programs.steam.enable = true;
        })
      ];
    };
  };
}
```

Alternatively, add the package directly without importing the module:

```nix
{ inputs, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      inputs.proton-cachy.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos
    ];
  };
}
```

After rebuilding NixOS, restart Steam. Select **Proton-CachyOS** under a game's
**Properties → Compatibility → Force the use of a specific Steam Play
compatibility tool** setting.

The package is also available as `packages.x86_64-linux.default`, and as
`proton-cachyos` from `overlays.default`.

## x86-64-v3 variant

CPUs supporting the x86-64-v3 feature set, including AVX2, can use the optimized
upstream archive instead:

```nix
programs.steam.extraCompatPackages = [
  inputs.proton-cachy.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos-x86_64-v3
];
```

It appears in Steam as **Proton-CachyOS (x86-64-v3)**. The default package and
NixOS module deliberately continue to use the conservative `x86_64` build. The
variant is also available as `proton-cachyos-x86_64-v3` from
`overlays.default`.

## Update automation

Renovate reads the latest stable GitHub release and the SHA-256 digests of its
`x86_64` and `x86_64_v3` archives from the upstream releases API. A release
update changes both versions and fixed-output hashes together. Renovate opens a
pull request for each new latest release and merges it only after the GitHub
Actions `test` check passes.

To activate this on a fork:

1. Install the [Renovate GitHub App](https://github.com/apps/renovate) for the
   repository.
2. Protect `main` and require the `test` status check before merging.

The flake lock file and pinned GitHub Actions are also kept current by
Renovate and follow the same test-before-merge policy.

## Local verification

```console
nix flake check
nix build .#proton-cachyos
nix build .#proton-cachyos-x86_64-v3
```
