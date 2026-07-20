{
  description = "Proton-CachyOS packaged as a Steam compatibility tool";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      proton-cachyos = pkgs.callPackage ./package.nix { };
      proton-cachyos-x86_64-v3 = pkgs.callPackage ./package.nix {
        variant = "x86_64_v3";
        steamDisplayName = "Proton-CachyOS (x86-64-v3)";
      };
    in
    {
      packages.${system} = {
        inherit proton-cachyos proton-cachyos-x86_64-v3;
        default = proton-cachyos;
      };

      checks.${system}.install-layout = pkgs.runCommand "proton-cachyos-install-layout" { } ''
        test -f ${proton-cachyos.steamcompattool}/compatibilitytool.vdf
        test -x ${proton-cachyos.steamcompattool}/proton
        grep -F '"display_name" "Proton-CachyOS"' \
          ${proton-cachyos.steamcompattool}/compatibilitytool.vdf
        test -f ${proton-cachyos-x86_64-v3.steamcompattool}/compatibilitytool.vdf
        test -x ${proton-cachyos-x86_64-v3.steamcompattool}/proton
        grep -F '"display_name" "Proton-CachyOS (x86-64-v3)"' \
          ${proton-cachyos-x86_64-v3.steamcompattool}/compatibilitytool.vdf
        touch $out
      '';

      overlays.default = final: _prev: {
        proton-cachyos = final.callPackage ./package.nix { };
        proton-cachyos-x86_64-v3 = final.callPackage ./package.nix {
          variant = "x86_64_v3";
          steamDisplayName = "Proton-CachyOS (x86-64-v3)";
        };
      };

      nixosModules.default =
        { pkgs, ... }:
        {
          programs.steam.extraCompatPackages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos
          ];
        };
    };
}
