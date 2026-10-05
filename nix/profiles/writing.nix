{ pkgs, ... }:

{
  home.packages = with pkgs; [
    languagetool
    pandoc
    typst
    vale
  ];

  # Shared presets, not another editor or background service. Output goes to
  # the explicitly chosen project Deliverables folder, never beside a draft.
  xdg.dataFile."pandoc/defaults/report-docx.yaml".text = ''
    from: markdown+wikilinks_title_after_pipe
    to: docx
    standalone: true
    metadata:
      lang: nl-NL
  '';
  xdg.dataFile."pandoc/defaults/report-pdf.yaml".text = ''
    from: markdown+wikilinks_title_after_pipe
    pdf-engine: typst
    standalone: true
    metadata:
      lang: nl-NL
    variables:
      mainfont: Open Sans
      papersize: a4
      margin:
        x: 2.5cm
        y: 2.5cm
  '';
}
