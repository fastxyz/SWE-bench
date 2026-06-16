# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit confirms that the one-line change in
`repo/django/db/migrations/autodetector.py` addresses the reported crash by
using `model_name` for the target `to_state` lookup in
`generate_renamed_fields()`, while preserving `old_model_name` for the
historical `from_state` lookup.

## Trace to FVK findings and obligations

F-001 identifies the V0 bug: after an accepted model rename `O -> N`, the
target state contains `(A, N)` and not `(A, O)`, so looking up
`to_state.models[(A, O)]` raises the reported `KeyError`. This is backed by
O-001, O-002, and O-003. V1 resolves it by looking up
`to_state.models[(A, N)]`, which is O-004.

F-002 confirms the old/new state-key split. O-001 establishes that
`renamed_models[(A, N)] = O` and later processing uses kept key `(A, N)`.
O-002 establishes that old field names are read from `from_state[(A, O)]` while
new field names are read from `to_state[(A, N)]`. Because V1 implements that
split directly, no additional source change was made.

F-003 confirms the non-renamed frame condition. O-005 shows that when there is
no model rename, `old_model_name == model_name`, so the V1 lookup is the same
target-state key as before. This rejected any broader refactor of field-key
preparation or rename handling.

F-004 records the proof boundary: the K model is focused on the state-key
property that produced the traceback, not on all migration autodetector
behavior. O-006 requires that limitation to remain explicit and prevents any
test-removal recommendation. This did not justify further source edits because
no uncovered public-intent obligation contradicted V1.

## Changes made in the FVK pass

Added the requested FVK Markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added constructed K artifacts required by the FVK methodology:

- `fvk/mini-django-autodetector.k`
- `fvk/autodetector-spec.k`

No files under `repo/` were changed during this FVK pass. No tests, Python, or
K commands were run.
