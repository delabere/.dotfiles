{ session-x
, brag
, goprotomocker
, workmux
, ...
} @ inputs: final: prev:
let
  system = final.stdenv.hostPlatform.system;
in
{
  brag = brag.packages.${system}.default;
  goprotomocker = goprotomocker.packages.${system}.default;
  workmux = (workmux.packages.${system}.default).overrideAttrs { doCheck = false; };

  tmuxPlugins =
    prev.tmuxPlugins
    // {
      session-x = session-x.packages.${system}.default;
    };
  plex = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      pname = "plexmediaserver";
      version = "1.42.1.10060-4e8b05daf";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "sha256:1x4ph6m519y0xj2x153b4svqqsnrvhq9n2cxjl50b9h8dny2v0is";
      };
      passthru = old.passthru // {
        inherit version;
      };
    });
  };
  sesh = prev.sesh.overrideAttrs (old: {
    nativeBuildInputs = builtins.filter (p: !(final.lib.hasInfix "mockery" (p.name or ""))) old.nativeBuildInputs;
    preBuild = "";
    doCheck = false;
  });

  # anyio's tests fail on python 3.12 here, so it isn't in the binary cache.
  # Scoped to 3.12 only: overriding it via pythonPackagesExtensions changes
  # anyio for every python, which knocks all of python 3.14 (Home Assistant,
  # afdko, ...) out of the cache and rebuilds hundreds of packages.
  python312 = prev.python312.override {
    packageOverrides = pyFinal: pyPrev: {
      anyio = pyPrev.anyio.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
  python312Packages = final.python312.pkgs;
}
