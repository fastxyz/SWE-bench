## FVK Decision

V1 stands unchanged. The audit found that the source edit in
`repo/lib/matplotlib/dates.py` satisfies the separator-protection contract:
spaces become `\;`, colons become `{:}`, and existing dash protection remains
`{-}`. This conclusion traces to `fvk/FINDINGS.md` F1 and
`fvk/PROOF_OBLIGATIONS.md` PO2-PO3.

## Source Changes

No V2 source files were edited.

I kept the V1 `_wrap_in_tex` implementation because F1 identifies the pre-V1
bug as raw spaces and colons inside TeX math chunks, and PO2-PO3 are discharged
by the current V1 replacement pipeline. F4 and PO5 show that fixing the helper
covers the built-in TeX date formatter paths.

I also kept the existing alphabetic split instead of switching to the exact
one-block monkey-patch shape from the issue comment. F3 records the ambiguity:
for `Jan-01`, the workaround form and V1 form both protect the separator, while
PO4 documents the compatibility reason for preserving alphabetic fragments
outside `\mathdefault`.

I did not change tests. F2 and PO7 mark the old raw-space/raw-colon expectations
as SUSPECT for this bug, but the task forbids test edits and the constructed
proof does not license test deletion.

## Artifact Changes

I added the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the FVK adequacy and formal-core artifacts required by the method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-datewrap.k`
- `fvk/datewrap-spec.k`

All proof claims are labeled constructed, not machine-checked. PO8 and F5 record
that no `kompile`, `kast`, `kprove`, Python, or test commands were run.
