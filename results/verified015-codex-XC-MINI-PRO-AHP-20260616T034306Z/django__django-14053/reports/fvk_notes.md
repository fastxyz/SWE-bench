# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Decision

V1 stands unchanged.

The FVK audit found that the V1 code satisfies the public intent for
`django__django-14053`: successful adjustable files are buffered during internal
multi-pass processing and emitted once with their final stored result. This is
the behavior required by Findings F-001 and F-002 and discharged by proof
obligations PO-002, PO-003, PO-004, and PO-007.

## Source Changes

No source files under `repo/` were changed during the FVK pass.

Reason: FINDINGS.md contains no code-bug finding against V1. F-001 confirms the
reported `admin/css/base.css` duplicate-yield shape is fixed by the deferred
adjustable map. F-002 confirms the stable-repeat case, such as the reported
`admin/css/dashboard.css` pattern, is also fixed because repeat assignments
replace the map value for the same original path.

## Error and Failure Behavior

V1's exception branches were kept unchanged after the audit. F-003 ties this to
PO-006 and PO-008: collectstatic expects exception tuples immediately, and V1
yields them immediately from both the initial and repeat loops.

The max-pass branch was also kept unchanged. F-004 ties this to PO-005 and
PO-006: V1 preserves the existing `All` `RuntimeError` surface and returns
before flushing buffered adjustable successes.

## Compatibility

No compatibility edit was needed. PO-008 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
show that V1 changes neither the public method signature nor the yielded tuple
shape. The only public timing change is that successful adjustable-file tuples
are delayed until the final hash is known, which is required by F-001 and F-002.

## Formalization Boundary

F-005 records the intentional abstraction boundary: the FVK model treats
`_post_process()` as an event source and proves the public yield policy. It does
not prove hash bytes, CSS parsing, or storage I/O. That boundary is sufficient
for this issue because PO-001 through PO-008 cover the observable named by the
problem: duplicate successful public yields by original filename.

## Artifacts Added

Added the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also added supporting FVK adequacy and formal files required by the method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/hashedfiles-post-process-spec.k`
