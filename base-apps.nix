{
  config,
  pkgs,
  brag,
  system,
  ...
}: let
  todo = pkgs.writeShellScriptBin "todo" ''
    [ ! -d "$HOME/notes" ] && mkdir "$HOME/notes"
    [ ! -f "$HOME/notes/todo.md" ] && touch "$HOME/notes/todo.md"
    nvim "$HOME/notes/todo.md"
  '';

  note = pkgs.writeShellScriptBin "note" ''
    [ ! -d "$HOME/notes" ] && mkdir -p "$HOME/notes"
    [ ! -f "$HOME/notes/$1.md" ] && touch "$HOME/notes/$1.md"
    nvim "$HOME/notes/$1.md"
  '';
  learnit = pkgs.writeShellScriptBin "learnit" ''
    [ ! -f "$HOME/learnit.txt" ] && touch "$HOME/learnit.txt"
    if [[ -z $1 ]]
    then
      cat $HOME/learnit.txt
    else
      echo "$(date +%d/%m/%Y) | $1" >> $HOME/learnit.txt
    fi
  '';
  gitprune =
    pkgs.writeShellScriptBin "gitprune" ''
    '';
in {
  home.packages = [
    todo
    note
    learnit
    gitprune
  ];
}
