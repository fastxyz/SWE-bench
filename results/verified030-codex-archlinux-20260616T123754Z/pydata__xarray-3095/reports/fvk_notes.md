# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original bug, confirmed that V1
discharges it, and found no additional source defect justified by public intent.

## Source-code decision

No V2 source edit was applied.

This decision is based on `fvk/FINDINGS.md` F-001 and
`fvk/PROOF_OBLIGATIONS.md` PO-3. F-001 identifies the real defect: the deep-copy
branch reconstructed `PandasIndexAdapter` without the original adapter dtype.
PO-3 shows V1 fixes that defect by passing `dtype=self._data.dtype` into the new
adapter, so an `IndexVariable` with unicode adapter dtype keeps that dtype after
`copy(deep=True)`.

The audit also considered the issue text's mention of `copy.copy()`. F-002 and
PO-2 show that, in this checkout, `copy.copy()` delegates to `copy(deep=False)`,
which reuses the existing adapter and therefore preserves dtype. The public hint
also says `DataArray.copy(deep=False)` is not affected. That is why no change to
`__copy__` or the shallow-copy branch was made.

Dataset, DataArray, and `copy.deepcopy()` behavior were kept as-is because PO-4,
PO-5, and PO-6 show they compose through the fixed `IndexVariable.copy` deep
branch. PO-7 shows V1 does not change a public signature or dispatch protocol.

## Artifact decisions

I added the requested FVK markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the supporting formal core required by the FVK docs:

- `fvk/mini-xarray-copy.k`
- `fvk/xarray-copy-spec.k`

The K model keeps the distinction between the dtype reported by the underlying
pandas index and the explicit dtype carried by `PandasIndexAdapter`. That
distinction is necessary for F-001: without it, a proof would not distinguish the
failing pre-fix `object` result from the intended `<U*>` result.

## Verification status

No tests, Python, or K tooling were run. F-003 and PO-8 record this as a proof
status limitation, not a code bug. The emitted commands in `fvk/PROOF.md` are
for a future human-run machine check only.
