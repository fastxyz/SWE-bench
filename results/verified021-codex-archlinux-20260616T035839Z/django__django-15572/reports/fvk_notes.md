# FVK Notes

## Decision log

Decision 1: keep the direct `backend.engine.dirs` empty-string guard.

Trace: `fvk/FINDINGS.md` F1 identifies the original regression mechanism, and
`fvk/PROOF_OBLIGATIONS.md` PO1 requires the empty string to contribute no path
before `to_path()` can normalize it.

Decision 2: keep the loader `get_dirs()` empty-string guard.

Trace: `fvk/FINDINGS.md` F2 shows that the filesystem loader can reintroduce
`engine.dirs`, and `fvk/PROOF_OBLIGATIONS.md` PO2 requires the same exclusion
for loader-provided values.

Decision 3: keep V1's exact `directory != ""` check rather than replacing it
with a broader truthiness filter.

Trace: `fvk/FINDINGS.md` F3 records the compatibility risk, while
`fvk/PROOF_OBLIGATIONS.md` PO3, PO4, and PO6 require non-empty values and
explicit current-directory paths to keep their previous normalization behavior.

Decision 4: make no additional production-code edits in the FVK pass.

Trace: `fvk/FINDINGS.md` reports no unresolved proof-derived code bug, and
PO1-PO6 are discharged by the current source in
`repo/django/template/autoreload.py`.

Decision 5: do not modify tests or run verification commands.

Trace: the task forbids test changes and code/tool execution. `fvk/PROOF.md`
therefore labels the proof constructed, not machine-checked, and records the
commands a maintainer could run later.

