{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  xz,
  steamDisplayName ? "Proton-CachyOS",
}:

let
  release = {
    version = "cachyos-11.0-20260702-slr";
    hash = "sha256:428d7a47b29519856e5bad50eb7e0f0123ec2431e2d37c31cebef2703f24f253";
  }; # renovate: proton-cachyos
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-cachyos";
  version = lib.removeSuffix "-slr" (lib.removePrefix "cachyos-" release.version);

  src = fetchurl {
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/${release.version}/proton-${release.version}-x86_64.tar.xz";
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
      --replace-fail "proton-${release.version}-x86_64" "${steamDisplayName}"

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
