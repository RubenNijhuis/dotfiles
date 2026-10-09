# Writing workflow

Draft in Obsidian. Keep each bounded writing/reporting project under
`~/Files/10 Projects/<Project Name>/`, or one named story folder inside the
Journalism category. Use `Sources/`, `Working/`, and `Deliverables/` only inside
that project when useful. Notes and reading references remain in Areas/Resources.

Nix supplies Pandoc, Typst, LanguageTool, and Vale on the Mac and Linux desktop.
It supplies two shared export presets, not another editor, a cloud checker,
or an always-running service. Native Windows applications are a separate layer;
WSL's lean developer target does not yet import the writing profile.

## Settings and templates

Obsidian's writable `.obsidian` settings and `30 Resources/Templates` already
belong to the iCloud-backed Files vault. Keep one live copy; do not symlink
those files into the read-only Nix store or import workspace/bookmark state
into Git. The current baseline uses Open Sans, relative Markdown links,
`00 Inbox` for new notes, and sibling `Attachments` folders.

The Nix Web Clipper import template matches the vault's source schema:
`type: bron`, `url`, `auteur`, `medium`, `geraadpleegd`, `leesstatus`, and
`dossier`. On a new browser, import
`~/.config/obsidian-web-clipper/research-source.json` through the extension.
Keep existing configured templates; import is not automatic and should not
create a second competing capture workflow.

HandBrake's [supported preset export/import](https://handbrake.fr/docs/en/latest/advanced/custom-presets.html)
is the boundary for reusable conversion settings. No custom preset file was
found at its documented Mac location on 2026-10-09; do not invent a preset
collection to back up. If a reusable preset becomes necessary, export it to
`~/Files/30 Resources/Media/Presets/`, not an app database or a machine-specific
path in Nix. Resolve project exports and source media belong to their specific
project, while reusable non-secret settings may be version-controlled separately.

## Export a draft

After activating Nix, from the specific project folder:

```sh
pandoc --defaults report-docx 'Working/Draft.md' -o 'Deliverables/Report.docx'
pandoc --defaults report-pdf 'Working/Draft.md' -o 'Deliverables/Report.pdf'
```

Create `Deliverables/` first and use a new filename if an export already exists;
Pandoc overwrites an existing output. The presets default to Dutch. Add
`-M lang=en-GB` for English. PDF uses A4 and Open Sans without installing TeX;
Word retains its standard document styles, which can be adjusted in the editor.
The [Pandoc defaults documentation](https://pandoc.org/demo/example33/5-defaults-files.html)
describes the shared preset mechanism.

Obsidian's own PDF export remains the simplest graphical option. The presets
are optional for repeatable deliverables. Internal wiki links are not exported
as complete linked vaults; check citations, attachments, footnotes, and layout
before sharing. Never treat an export as approval to publish.

## Dutch and English checks, locally

Export a temporary plain-text copy outside your vault, then review suggestions:

```sh
draft_text="$(mktemp -t writing-check)"
pandoc 'Working/Draft.md' --to plain -o "$draft_text"
languagetool-commandline --language nl "$draft_text"
# Or: languagetool-commandline --language en-GB "$draft_text"
rm "$draft_text"
```

Use `languagetool-commandline`, not `languagetool` (the latter launches its GUI).
These local checks do not need a cloud account. Do not use `--apply`: suggestions
need judgment. Vale remains an optional project-level style checker; no downloaded
English style pack is silently imposed on Dutch prose. Markdown, human review,
and a stable export path are the baseline, not a collection of plugins.

The flake includes a writing smoke test for hosts importing this profile. It
tests Word/PDF generation and Dutch/English grammar examples without reading
your notes. Run `bash tests/test-writing.sh` after activation for the local test.
