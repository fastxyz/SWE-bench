# Iteration Guidance

Status: constructed, not machine-checked.

## Code decisions made in V2

- Apply F-001 / PO-4: broadened `_emit_source_read_on_include` so it patches a
  direct `FileInput` global in `BaseInclude.run` when present, in addition to
  `docutils.io.FileInput`.
- Apply F-002 / PO-6: updated `sphinx.ext.duration.on_source_read` so the first
  source-read event in a document read starts the timer and include-triggered
  source-read events do not reset it.

## Tests to add outside this benchmark

- Build a document matching the issue reproduction and assert both paragraphs
  render `REPLACED`.
- Include a file with a non-source suffix such as `.inc` and assert a
  `source-read` handler replacement affects the inserted text.
- Include a docutils standard include such as `<isonum.txt>` and assert Sphinx
  does not treat it as a source-directory file.
- Exercise `.. include:: file` with representative docutils options such as
  `:literal:` and `:encoding:` to confirm delegation remains intact.
- Enable `sphinx.ext.duration` on a document with includes and assert a
  successful build with one duration entry for the containing document.
- Enable `sphinx.ext.intersphinx` on a document with included content that uses
  roles and assert role resolution still works.

## Machine-check commands

Do not run these in this benchmark session. They are recorded for a future
environment with K installed:

```sh
kompile fvk/mini-sphinx-include.k --backend haskell
kast --backend haskell fvk/sphinx-include-spec.k
kprove fvk/sphinx-include-spec.k
```

## Residual risk

- The formal model abstracts docutils internals. The source fix intentionally
  keeps docutils in charge of include semantics, so integration tests remain
  necessary.
- The formal model does not cover intersphinx dispatcher stacking when
  `source-read` fires during parsing; public integration coverage should keep
  that listener honest.
- The proof is constructed, not machine-checked. Do not remove tests based on it
  until `kprove` returns `#Top`.
