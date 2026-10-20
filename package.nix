{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  xz,
  variant ? "x86_64",
  steamDisplayName ? if variant == "x86_64" then "Proton-CachyOS" else "Proton-CachyOS (${variant})",
}:

let
  releases = {
    x86_64 = {
      version = "cachyos-11.0-20261015-slr";
      hash = "sha256:35e16eab636724e3ed7aa8e2dbc33eb8e102e0c63bbc28b5a39af544c75d5bd3";
    }; # renovate: proton-cachyos-x86_64
    x86_64_v3 = {
      version = "cachyos-11.0-20261015-slr";
      hash = "sha256:4f125bd7d2c724dc7d2d0553ca42f18c67022a6006e8629fe7f78d160a9ebdfb";
    }; # renovate: proton-cachyos-x86_64_v3
  };
  release = releases.${variant} or (throw "Unsupported Proton-CachyOS variant: ${variant}");
in
assert releases.x86_64.version == releases.x86_64_v3.version;
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = if variant == "x86_64" then "proton-cachyos" else "proton-cachyos-${variant}";
  version = lib.removeSuffix "-slr" (lib.removePrefix "cachyos-" release.version);

  src = fetchurl {
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/${release.version}/proton-${release.version}-${variant}.tar.xz";
    inherit (release) hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # This is a complete Steam Runtime build; Nix must not rewrite its bundled
  # ELF RPATHs or script interpreters during the generic fixup phase.
  dontFixup = true;

  nativeBuildInputs = [
    gnutar
    xz
  ];

  outputs = [
    "out"
    "steamcompattool"
  ];

  installPhase = ''
    runHook preInstall

    echo "${finalAttrs.pname} is a Steam compatibility tool. Add it with programs.steam.extraCompatPackages." > "$out"

    mkdir -p "$steamcompattool"
    tar --extract --xz --file="$src" --directory="$steamcompattool" --strip-components=1

    test -f "$steamcompattool/compatibilitytool.vdf"
    test -x "$steamcompattool/proton"

    substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
      --replace-fail "proton-${release.version}-${variant}" "${steamDisplayName}"

    runHook postInstall
  '';

  meta = {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
