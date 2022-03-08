{ pkgs, fetchFromSourcehut, nodejs-14_x, stdenv, lib }:

let
  src = fetchFromSourcehut {
    owner = "~cadence";
    repo = "bibliogram";
    rev = "6b667f5f00478508d1e0698d9ee4836c7b45e57a";
    sha256 = "sha256-5zn3N1W/4Fw1IsDToLWiXSdw1M4K7yHxyA62AnfJFyE=";
  };

  nodePackages = import ./node-composition.nix {
    inherit pkgs;
    nodejs = nodejs-14_x;
    inherit (stdenv.hostPlatform) system;
  };
in
nodePackages.package.override {
  inherit src;
  # passthru.updateScript = ./generate-dependencies.sh;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  preRebuild = ''
    # Don't try to install the tor browser bundle.
    export GRANAX_USE_SYSTEM_TOR=true
  '';

  # FIXME the resulting program is not actually amenable to being run in nix, as
  # it wants to mutate hard-coded directories within the repository, where it
  # puts the database. Perhaps this could be fixed with some symlinks?
  #
  # The CWD absolutely can't be changed from where `npm start` puts it (inside
  # the repository) due to large parts of the project and its dependencies
  # making assumptions about paths relative to that directory. Pretty cursed!
  #
  # Example error:
  # ~/nixpkgs master• λ /nix/store/wmzxgn0nl13jss1fydlkw750szvcrpsy-bibliogram-1.0.0/bin/bibliogram
  # (node:77985) UnhandledPromiseRejectionWarning: Error: EACCES: permission denied, mkdir '/nix/store/wmzxgn0nl13jss1fydlkw750szvcrpsy-bibliogram-1.0.0/lib/node_modules/bibliogram/db/backups'
  #     at Object.mkdirSync (fs.js:1013:3)
  #     at Object.<anonymous> (/nix/store/wmzxgn0nl13jss1fydlkw750szvcrpsy-bibliogram-1.0.0/lib/node_modules/bibliogram/src/lib/db.js:6:4)
  #     at Module._compile (internal/modules/cjs/loader.js:1085:14)
  #     at Object.Module._extensions..js (internal/modules/cjs/loader.js:1114:10)
  #     at Module.load (internal/modules/cjs/loader.js:950:32)
  #     at Function.Module._load (internal/modules/cjs/loader.js:790:12)
  #     at Module.require (internal/modules/cjs/loader.js:974:19)
  #     at require (internal/modules/cjs/helpers.js:101:18)
  #     at Object.<anonymous> (/nix/store/wmzxgn0nl13jss1fydlkw750szvcrpsy-bibliogram-1.0.0/lib/node_modules/bibliogram/src/lib/utils/upgradedb.js:3:12)
  #     at Module._compile (internal/modules/cjs/loader.js:1085:14)
  # (Use `node --trace-warnings ...` to show where the warning was created)
  # (node:77985) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 1)
  # (node:77985) [DEP0018] DeprecationWarning: Unhandled promise rejections are deprecated. In the future, promise rejections that are not handled will terminate the Node.js process with a non-zero exit code.

  postInstall = ''
    mkdir -p $out/bin

    # bibliogram provides no binary entrypoint. It is also sensitive to cwd.
    # Create a script that does the same thing `npm run start` does.
    cat<<EOF > $out/bin/bibliogram
    #!$SHELL
    cd $out/lib/node_modules/bibliogram/src/site
    node server.js
    EOF

    chmod +x $out/bin/bibliogram

    wrapProgram "$out/bin/bibliogram" --prefix PATH : "${lib.makeBinPath [ nodejs-14_x pkgs.graphicsmagick ]}"
  '';

  meta = with lib; {
    # There are no actual releases for this project.
    version = "unstable-2022-03-07";
    description = "An alternative front-end for Instagram";
    homepage = "https://git.sr.ht/~cadence/bibliogram";
    maintainers = with maintainers; [];
    license = licenses.agpl3Only;
  };
}
