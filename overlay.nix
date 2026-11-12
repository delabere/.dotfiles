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
}
