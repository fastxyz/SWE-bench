# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit localized the issue to the `level is not None` branch of
`PandasMultiIndexingAdapter.__array__` (`F1`, `PO3`, `PO4`). V1 already fixes
that branch by defaulting `dtype` to `self.dtype` and passing the effective dtype
to `np.asarray`.

## Why No Additional Source Change Was Made

`F2` and `PO2` show that `PandasMultiIndex.stack` already records the original
coordinate dtype in `level_coords_dtype`, and `PandasMultiIndex.create_variables`
already passes that dtype into `PandasMultiIndexingAdapter`. Editing those
producer paths would not address a remaining obligation.

`F3` and `PO5` confirm that V1 preserves explicit dtype override behavior: the
stored dtype is used only when `dtype is None`.

`F4` and `PO7` confirm that V1 leaves the `level is None` path delegated to the
base adapter, so aggregate MultiIndex conversion is not broadened by the fix.

`PO8` is discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: the method
signature, return type, NumPy protocol shape, and producer/consumer metadata
shape are unchanged.

## Artifacts Written

The requested FVK files are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK adequacy and formal-core files are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-indexing.k`
- `fvk/pandas-multi-indexing-adapter-spec.k`

## Verification Caveat

`F5` and `PO9` remain as the honesty gate: the proof is constructed, not
machine-checked, because this task forbids running Python, tests, or K tooling.
No tests were modified or removed.

