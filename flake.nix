{
  description = "Proton-CachyOS packaged as a Steam compatibility tool";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      proton-cachyos = pkgs.callPackage ./package.nix { };
    in
    {
      packages.${system} = {
        inherit proton-cachyos;
        default = proton-cachyos;
      };

      checks.${system}.install-layout = pkgs.runCommand "proton-cachyos-install-layout" { } ''
        test -f ${proton-cachyos.steamcompattool}/compatibilitytool.vdf
        test -x ${proton-cachyos.steamcompattool}/proton
        touch $out
      '';

      overlays.default = final: _prev: {
        proton-cachyos = final.callPackage ./package.nix { };
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
