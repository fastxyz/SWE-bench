# ITERATION GUIDANCE

Status: FVK improvement guidance after auditing V1.

## Code Decision

Keep V1 unchanged.

Reason: `fvk/FINDINGS.md` F1 is fixed by the current source change, and `fvk/PROOF_OBLIGATIONS.md` PO2 and PO3 discharge the root no-mutation and split-array independence obligations. No open code finding remains.

## Rejected Follow-Up Change

Do not add a second fix in `SplitArrayWidget.get_context()` for this issue. F3 explains why copying in the array widget is optional hardening rather than the public-intent fix: V1 removes the mutation at `CheckboxInput.get_context()`, the identified root cause.

## Future Test Work

The benchmark forbids test edits, but a normal project follow-up should add regression coverage for:

- boolean split array values `[False, True, False]` rendering only the middle checkbox as checked;
- the same path with an `id` attr;
- direct immutability of the attrs dict passed to `CheckboxInput.get_context()`.

Keep existing tests until a real K run returns `#Top`; do not remove tests based only on this constructed proof.

## Verification Work

When an execution environment exists, run:

```sh
cd fvk
kompile mini-django-widgets.k --backend haskell
kast --backend haskell checkbox-splitarray-spec.k
kprove checkbox-splitarray-spec.k
```

If these commands do not discharge to `#Top`, repair the K artifacts first. The source-level reasoning still supports V1, but the FVK proof must remain labeled constructed until machine-checked.
