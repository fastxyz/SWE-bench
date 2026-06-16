# FVK Spec

Status: constructed, not machine-checked.

## Scope

The spec covers the behavioral surface changed for sphinx-doc__sphinx-11510:

- `repo/sphinx/directives/other.py`: `_emit_source_read_on_include` and
  `Include.run`
- `repo/sphinx/ext/duration.py`: `on_source_read`

The proof is partial correctness over a small abstract model of Sphinx include
processing. It does not model all of docutils or all of Sphinx.

## Intent Ledger

The ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are:

- E1-E6: public issue evidence requires `source-read` mutations to affect
  included source inserted into the including document.
- E7: top-level source reading emits `source-read` and returns the handler's
  replacement text.
- E8-E9: Sphinx include path behavior and docutils include option behavior are
  frame conditions.
- E10: in-tree event listeners must remain compatible with additional include
  events.

## Abstract State

The K model in `mini-sphinx-include.k` uses these observable cells:

- `<files>` maps include filenames to raw source text.
- `<pathdocs>` maps filenames to source docnames when Sphinx can derive one.
- `<events>` records emitted `source-read` docnames and source text.
- `<inserted>` records the source text that docutils inserts for an include.
- `<fileInput>` and `<directFileInput>` model docutils resolving `FileInput`
  through the `docutils.io` module or through a direct global imported into
  `Include.run`.
- `<durationStarted>` models whether `sphinx.ext.duration` has already recorded
  the document start time.

The abstract function `sourceRead(DOC, SRC)` denotes the result of all connected
`source-read` handlers applied to `SRC` for `DOC`. It is intentionally
uninterpreted: FVK proves that Sphinx uses the returned value, not any particular
extension's replacement algorithm.

## Preconditions

P1. The include target exists and docutils' include implementation reads it
through either `docutils.io.FileInput` or a direct `FileInput` global in
`BaseInclude.run`.

P2. `source-read` handlers terminate and return a string in `source[0]`.

P3. The include directive argument is either a docutils standard include of the
form `<name>` or a Sphinx-managed include path. Other docutils validation and
error behavior remains delegated to `BaseInclude.run`.

## Postconditions

S1. For a Sphinx-managed include, the inserted text is
`sourceRead(include_docname(FILE), raw_file_text(FILE))`.

S2. `include_docname(FILE)` is `env.path2doc(FILE)` when that returns a docname;
otherwise it is `env.docname`.

S3. Both modeled `FileInput` lookup channels are restored to their original
values after `BaseInclude.run()` returns or raises.

S4. For a standard include `<name>`, Sphinx does not apply Sphinx path handling,
does not emit this include-side `source-read`, and delegates to docutils'
standard include behavior unchanged.

S5. `Include.run()` still delegates the actual include processing to
`BaseInclude.run()`, preserving docutils options and dependency recording.

S6. `duration.on_source_read()` sets `started_at` only if the current document
read has not already recorded a start time; later include-triggered source-read
events do not reset it.

## Frame Conditions

F1. Public signatures are unchanged.

F2. `env.note_included(filename)` remains in the Sphinx-managed include path.

F3. No test files are modified.
