#!/usr/bin/env bash
# Local export/grammar smoke test; samples stay in a disposable directory.
set -euo pipefail
docx_preset="${1:-$HOME/.local/share/pandoc/defaults/report-docx.yaml}"
pdf_preset="${2:-$HOME/.local/share/pandoc/defaults/report-pdf.yaml}"
[[ -f "$docx_preset" && -f "$pdf_preset" ]] || { echo 'Writing presets are not activated'; exit 1; }
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

# A short, synthetic draft tests formatting without reading personal notes.
printf '%s\n' '---' 'title: Exportcontrole' '---' '' '# Verwijzingen' \
  'Een alinea met **nadruk**, café en een voetnoot.[^1]' '' \
  '[^1]: Voetnoot voor de exportcontrole.' > "$fixture/draft.md"
pandoc --defaults "$docx_preset" "$fixture/draft.md" -o "$fixture/report.docx"
pandoc --defaults "$pdf_preset" "$fixture/draft.md" -o "$fixture/report.pdf"
unzip -t "$fixture/report.docx" >/dev/null
[[ "$(head -c 4 "$fixture/report.pdf")" == '%PDF' ]]
pandoc "$fixture/report.docx" --to plain | grep -q 'Voetnoot voor de exportcontrole'

printf 'Ik vindt dit belangrijk.\n' > "$fixture/nl.txt"
printf 'She go to school every day.\n' > "$fixture/en.txt"
for language in nl en-GB; do
  input="nl"
  [[ "$language" == nl ]] || input=en
  languagetool-commandline --language "$language" --json "$fixture/$input.txt" \
    | jq -e '.matches | length > 0' >/dev/null
done
printf 'writing: Word/PDF exports and Dutch/English checks passed\n'
