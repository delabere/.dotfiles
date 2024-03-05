{session-x, ...} @ inputs: final: prev: {
  tmuxPlugins =
    prev.tmuxPlugins
    // {
      session-x = session-x.packages.${final.system}.default;
    };
}
