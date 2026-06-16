# FVK Notes

## Decision

V1 stands unchanged. The audit did not justify any further source edit under `repo/`.

## Trace to findings and proof obligations

Finding F1 identifies the original bug: pre-V1 `Float.__eq__` reached the zero-Float shortcut before rejecting `S.false`. Proof obligation PO1 is the required repair. V1 discharges PO1 because `Float.__eq__` now returns `False` immediately for operands that are already instances of SymPy `Boolean`.

Finding F2 is the key minimality check. A broader edit that moved the post-sympification Boolean guard ahead of the zero shortcut would also affect native `False`, because `_sympify(False)` becomes `S.false`. PO2 preserves the distinction supported by public tests: native `False` is not the same input as `S.false` before sympification. V1 satisfies PO2 because the early guard checks `Boolean`, not Python `bool`.

Finding F3 rules out changing `BooleanAtom`, `Boolean`, or `Basic`: the issue already reports `S.false == S(0.0)` as `False`. PO4 records that reverse comparison as an unchanged behavior. No source edit outside `Float.__eq__` is justified.

Finding F4 confirms the numeric branches are framed. PO3 and PO5 require the existing numeric and `NotImplemented` paths to remain reachable for non-Boolean operands. V1 adds only the early already-SymPy-Boolean guard, so no numeric comparison branch needs revision.

Finding F5 records the verification limitation. PO6 is satisfied by labeling all proof artifacts constructed and not machine-checked, and by not running tests, Python, `kompile`, or `kprove`.

## Artifact changes

I added the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added supporting formal-core sketches required by the FVK method:

- `fvk/mini-sympy-eq.k`
- `fvk/float-eq-spec.k`

These `.k` files model only the operand categories needed for the defect: zero/nonzero Float, already-SymPy Boolean operands, native Python booleans before sympification, numeric frame operands, and unsympifiable operands.

No test files were modified.
