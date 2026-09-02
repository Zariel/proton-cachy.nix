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
      version = "cachyos-11.0-20260703-slr";
      hash = "sha256:62ff4b2750180723cc00538608fe687e21d1d91a31ef64ce1a7c9f46c3db310b";
    }; # renovate: proton-cachyos-x86_64
    x86_64_v3 = {
      version = "cachyos-11.0-20260703-slr";
      hash = "sha256:03ecd42bd7d474e9ba443ce8972d9678a1fa3acbf2920d761f35397946ece284";
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
