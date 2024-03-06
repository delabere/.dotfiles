{
  session-x,
  brag,
  ...
} @ inputs: final: prev: {
  brag = brag.packages.${final.system}.default;

  tmuxPlugins =
    prev.tmuxPlugins
    // {
      session-x = session-x.packages.${final.system}.default;
    };
}
