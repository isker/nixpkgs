{ lib
, stdenv
, fetchFromGitLab
, nix-update-script
, # base build deps
  meson
, pkg-config
, ninja
, # docs build deps
  python3
, doxygen
, graphviz
, # GI build deps
  gobject-introspection
, # runtime deps
  glib
, systemd
, lua5_4
, pipewire
, # options
  enableDocs ? true
, enableGI ? stdenv.hostPlatform == stdenv.buildPlatform
}:
let
  mesonEnableFeature = b: if b then "enabled" else "disabled";
in
stdenv.mkDerivation rec {
  pname = "wireplumber";
  version = "0.4.9";

  outputs = [ "out" "dev" ] ++ lib.optional enableDocs "doc";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "pipewire";
    repo = "wireplumber";
    rev = version;
    sha256 = "sha256-U92ozuEUFJA416qKnalVowJuBjLRdORHfhmznGf1IFU=";
  };

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
  ] ++ lib.optionals enableDocs [
    graphviz
  ] ++ lib.optionals enableGI [
    gobject-introspection
  ] ++ lib.optionals (enableDocs || enableGI) [
    doxygen
    (python3.withPackages (ps: with ps;
    lib.optionals enableDocs [ sphinx sphinx_rtd_theme breathe ] ++
      lib.optionals enableGI [ lxml ]
    ))
  ];

  buildInputs = [
    glib
    systemd
    lua5_4
    pipewire
  ];

  mesonFlags = [
    "-Dsystem-lua=true"
    "-Delogind=disabled"
    "-Ddoc=${mesonEnableFeature enableDocs}"
    "-Dintrospection=${mesonEnableFeature enableGI}"
    "-Dsystemd-system-service=true"
    "-Dsystemd-system-unit-dir=${placeholder "out"}/lib/systemd/system"
    "-Dsysconfdir=/etc"
  ];

  passthru.updateScript = nix-update-script {
    attrPath = pname;
  };

  meta = with lib; {
    description = "A modular session / policy manager for PipeWire";
    homepage = "https://pipewire.org";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ k900 ];
  };
}
