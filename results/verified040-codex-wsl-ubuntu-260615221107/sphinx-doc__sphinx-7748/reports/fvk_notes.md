# FVK Notes

## Decision

The FVK audit confirms the V1 source fix should stand unchanged.

No production source files were edited during the FVK phase.  The audit found
that the current code satisfies the public intent and the proof obligations over
the specified finite-docstring domain.

## Trace to findings and obligations

`repo/sphinx/ext/autodoc/__init__.py`

Kept unchanged because F-01 discharges the issue's central defect: V1 collects
all consecutive leading valid signatures instead of only the first.  This maps
to PO-1 and PO-2.

Kept the leading-only scan because F-02 shows that scanning later docstring
paragraphs would exceed the public contract and risk stripping examples or
prose.  This maps to PO-3 and PO-8.

Kept the `_find_signature()` compatibility wrapper because F-03 requires the
legacy first-signature return shape for existing callers.  This maps to PO-4 and
PO-5.

Kept the no-cache behavior in `_find_signature()` because F-04 identifies the
strip-only compatibility risk.  If `_find_signature()` populated
`_docstring_signatures`, `DocstringStripSignatureMixin` could re-emit a stripped
signature on delegation.  The current source avoids that, satisfying PO-6.

Kept newline-separated formatting because F-01 and PO-7 show it matches the
existing `Documenter.add_directive_header()` consumer, which already emits one
directive signature per newline.

Kept explicit-signature bypass behavior because PO-9 is already enforced by the
existing `self.args is None` guard.

## Non-code follow-ups

F-05 notes that user documentation still says "the first line".  I did not edit
documentation in this FVK pass because the benchmark task asks to confirm or
revise the source fix, and the runtime behavior is already covered by PO-1
through PO-9.  A normal project PR should update the docs wording.

## Verification status

The FVK proof is constructed, not machine-checked.  Per the task constraints, I
did not run tests, Python, `kompile`, `kast`, or `kprove`.  The commands to run
later are recorded in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.
