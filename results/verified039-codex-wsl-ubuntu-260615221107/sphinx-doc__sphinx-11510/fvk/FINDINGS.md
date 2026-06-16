# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
intent, source inspection, and proof obligations; no tests or code were run.

## F-001: V1 FileInput interception depended on docutils import style

Input -> observed vs expected:

- Input: a docutils `Include.run()` implementation that resolves `FileInput`
  from a direct global imported as `from docutils.io import FileInput`.
- V1 observed behavior by source reasoning: `_emit_source_read_on_include`
  replaced `docutils.io.FileInput`, but the direct global would still point to
  the original class. The include read could therefore insert raw `SRC`.
- Expected: any include read that docutils performs through its `FileInput`
  abstraction should be intercepted so that inserted text is `sourceRead(DOC,
  SRC)`.

Classification: code robustness bug / proof obstacle.

Resolution: fixed in V2. The helper now also patches `BaseInclude.run`'s direct
`FileInput` global when that global exists and is the original docutils input
class, then restores it in `finally`.

Proof obligation: PO-4.

## F-002: V1 could make `sphinx.ext.duration` undercount documents with includes

Input -> observed vs expected:

- Input: a document read where the top-level source fires `source-read`, then a
  managed include fires another `source-read` before `doctree-read`.
- V1 observed behavior by source reasoning: `duration.on_source_read()` always
  replaced `started_at`, so the measured duration could start at the later
  include event.
- Expected: reading duration should measure the document read from the first
  source-read event in that read.

Classification: public compatibility issue for an in-tree event listener.

Resolution: fixed in V2. `duration.on_source_read()` now only sets
`started_at` if it is not already present in `env.temp_data`.

Proof obligation: PO-6.

## F-003: Full docutils include semantics are outside the mini-K model

Input -> observed vs expected:

- Input: include options such as `:literal:`, `:code:`, `:encoding:`, line
  slicing, dependency recording, and nested parser insertion.
- Observed in the formal model: these details are abstracted as
  `baseIncludeRead`.
- Expected: the production fix must preserve them.

Classification: proof capability boundary, not a current code bug.

Resolution: V2 keeps delegation to `super().run()` and only wraps the file input
read, satisfying PO-3 at source level. Public tests should still cover a few
representative docutils include options because the constructed proof abstracts
them.

Proof obligation: PO-3.

## F-004: Hidden tests cannot be used as evidence

Input -> observed vs expected:

- Input: no visible test results and no permitted execution environment.
- Observed: FVK cannot machine-check the K claims or run Sphinx builds here.
- Expected: artifacts must state constructed, not machine-checked, and recommend
  tests without editing them.

Classification: process limitation / honesty gate.

Resolution: all FVK proof artifacts are labeled constructed, not
machine-checked. No test files were modified.

Proof obligation: PO-7.
