{ session-x
, brag
, goprotomocker
, workmux
, agenix
, ...
} @ inputs: final: prev:
let
  system = final.stdenv.hostPlatform.system;
in
{
  brag = brag.packages.${system}.default;
  goprotomocker = goprotomocker.packages.${system}.default;
  workmux = (workmux.packages.${system}.default).overrideAttrs { doCheck = false; };
  # x86_64-linux builds run under Rosetta on the Mac (nix-rosetta-builder), and
  # Go's AVX2 chacha20-poly1305 code miscomputes there: age fails with
  # "failed to decrypt and authenticate payload chunk" in agenix's rekey test.
  # Keep the tests, just on the non-AVX2 code path.
  agenix = agenix.packages.${system}.default.overrideAttrs (old: {
    postInstallCheck = "export GODEBUG=cpu.avx2=off\n" + old.postInstallCheck;
  });

  tmuxPlugins =
    prev.tmuxPlugins
    // {
      session-x = session-x.packages.${system}.default;
    };
}
