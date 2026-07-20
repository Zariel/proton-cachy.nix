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
      version = "cachyos-11.0-20260702-slr";
      hash = "sha256:428d7a47b29519856e5bad50eb7e0f0123ec2431e2d37c31cebef2703f24f253";
    }; # renovate: proton-cachyos-x86_64
    x86_64_v3 = {
      version = "cachyos-11.0-20260702-slr";
      hash = "sha256:11397853eb95f8fb448535cebe2655471306c80c3456c46b52cd568708a4fe5c";
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
