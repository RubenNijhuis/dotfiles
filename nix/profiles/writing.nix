{ pkgs, ... }:

{
  home.packages = with pkgs; [
    languagetool
    pandoc
    typst
    vale
  ];
}
