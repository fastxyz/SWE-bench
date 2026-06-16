# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Summary

The proof is over the abstract pyreverse type-collection model in
`mini-pyreverse.k` and the claims in `pyreverse-typehints-spec.k`. It establishes
partial correctness of the audited behavior: if pyreverse reaches the modeled
collection/rendering steps, the collected type evidence satisfies the issue's
direct annotation obligations.

## Claims And Proof Sketch

### PARAM-ANNOTATION-COLLECTED

Initial state: `collectAssignAttr`, value-inference result `VS`, no direct
`AnnAssign`, and parameter annotation `ann(T)`.

Symbolic execution:

1. Apply the `collectAssignAttr` rule.
2. `annTypes(noAnn)` rewrites to `.Types`.
3. `annTypes(ann(T))` rewrites to `types(T, .Types)`.
4. The collected result is `merge(merge(VS, .Types), types(T, .Types))`.
5. Simplification of `merge(VS, .Types)` yields `VS`, so the result is
   `merge(VS, types(T, .Types))`.

This discharges PO1.

### ANNASSIGN-COLLECTED

Initial state: `collectAssignName` or `collectAssignAttr`, value-inference
result `VS`, and direct assignment annotation `ann(T)`.

Symbolic execution applies the corresponding collection rule and the
`annTypes(ann(T))` rule, yielding `merge(VS, types(T, .Types))`. This discharges
PO2 for both assignment target kinds.

### NO-ANNOTATION-PRESERVES-VALUE-INFERENCE

Initial state: `collectAssignAttr`, value-inference result `VS`, no direct
annotation, and no parameter annotation.

Symbolic execution applies `collectAssignAttr`. Both annotation functions
rewrite to `.Types`; merge identity reduces the result to `VS`. This discharges
PO5.

### DISPLAY-BUILTIN-TYPE

Initial state: collection followed by render, value-inference result
`types(NoneType, .Types)`, parameter annotation `builtin(str)`, and no diagram
node for `str`.

Symbolic execution:

1. Collection yields `types(NoneType, types(builtin(str), .Types))`.
2. Rendering applies `visible`.
3. `hiddenForDisplay(NoneType, .Types)` is true, so `NoneType` is suppressed.
4. `hiddenForDisplay(builtin(str), .Types)` is false, so `builtin(str)` remains.

The displayed result is `types(builtin(str), .Types)`, discharging PO4.

### DISPLAY-SUPPRESSES-DIAGRAM-NODE

Initial state: collected type `user(Thing)` and `diagramTypes` containing
`user(Thing)`.

Rendering applies `visible`; `hiddenForDisplay(user(Thing), diagramTypes)` is
true because `contains(diagramTypes, user(Thing))` is true. The displayed type
list is empty. The raw collected type remains available before rendering, which
matches the existing association path. This discharges PO6.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` compares those
paraphrases against `INTENT_SPEC.md` and marks all proven obligations as pass.
The only broader intent phrase, "PEP 484", is bounded explicitly by F3 and PO7.

## Reproduce The Machine Check Later

These commands are recorded only; they were not executed:

```sh
kompile fvk/mini-pyreverse.k --backend haskell
kast --backend haskell fvk/pyreverse-typehints-spec.k
kprove fvk/pyreverse-typehints-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`.

## Test Recommendation

No tests were run or modified. If the K claims are machine-checked later, unit
tests that assert the exact in-domain direct-annotation cases are partially
subsumed by the proof. Keep integration tests, pyreverse writer tests, complex
PEP 484 expression tests, and any tests for astroid-specific inference behavior.
