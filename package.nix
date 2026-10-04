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
      version = "cachyos-11.0-20261005-slr";
      hash = "sha256:096bfe73b506d6565b04ecc45214197a4091818f16ed91f5324b4d2082d0a263";
    }; # renovate: proton-cachyos-x86_64
    x86_64_v3 = {
      version = "cachyos-11.0-20261005-slr";
      hash = "sha256:ba52a4f31a060ffca2b8e05fc00e51bc39e4c1501928eb5a9218b0fa07bfc8c7";
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
