# FVK Notes

## Decision Summary

The FVK audit confirms V1 and does not justify a V2 source edit. The source
remains changed only as in V1:

- `repo/src/_pytest/unittest.py` records `_explicit_tearDown` only when
  unittest actually calls the replacement `tearDown` under `--pdb`.

## Trace To Findings And Proof Obligations

F-001 is the original bug: a decorator-skipped unittest method under `--pdb`
must not run `tearDown`. PO-1 proves the V1 scheduling state for that case:
after setup, `runtest(true, false)`, and pytest item teardown, the delayed
teardown count is unchanged and `_explicit_tearDown` is empty. This is why I
kept the V1 closure-based recording approach.

F-002 is the preservation obligation for tests that do reach unittest teardown
under `--pdb`. PO-2 proves that when unittest calls the replacement
`tearDown`, V1 records the original bound method and pytest item teardown calls
it exactly once later. This rejects the alternative of simply suppressing all
`tearDown` calls under `--pdb`.

PO-3 confirms the non-`--pdb` frame condition: the delayed-teardown mechanism
does not schedule an extra call outside pdb mode. This supports leaving the
non-pdb branch unchanged.

F-003 and PO-4 cover compatibility. The audit found no public signature, hook,
callback, or subclass contract change. The temporary replacement `tearDown`
accepts `*args, **kwargs`, which is no less compatible than the previous no-op
replacement. Therefore no compatibility-driven source edit is needed.

PO-5 confirms adequacy: the formal claims are derived from the issue and public
repo evidence, and the model distinguishes V1 from the buggy predecessor. The
predecessor would save `tearDown` before unittest ran; in the skipped path that
would make pytest item teardown increment the delayed-call count, violating
PO-1.

F-004 records the verification caveat. The proof is constructed, not
machine-checked, because this task forbids running K tooling. This affects proof
confidence and test-removal recommendations, but it does not create a source
change because the code decision is derived from the intent and symbolic state
transition.

## Artifacts Written

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK contract artifacts:

- `fvk/mini-pytest-unittest.k`
- `fvk/pytest-unittest-teardown-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Commands Not Run

Per the task constraints, I did not run tests, Python, `kompile`, `kast`, or
`kprove`. The K commands are recorded in `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md` for a later unrestricted environment.
