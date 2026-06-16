# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent and
static source reasoning only.

## F-001: deep copy rebuilt the adapter without dtype metadata

Input: an `IndexVariable` whose underlying pandas index reports `object` but
whose `PandasIndexAdapter` exposes fixed-width unicode dtype `<U3`.

Observed in V0: `IndexVariable.copy(deep=True)` built
`PandasIndexAdapter(self._data.array.copy(deep=True))`. The new adapter inferred
dtype from the copied pandas index, so xarray exposed `object`.

Expected: the copied `IndexVariable` exposes the original adapter dtype `<U3`.

Classification: code bug, resolved by V1.

Resolution: V1 changes the deep-copy branch to
`PandasIndexAdapter(self._data.array.copy(deep=True), dtype=self._data.dtype)`.
This preserves the adapter dtype while keeping the copied pandas index.

Trace: SPEC E1, E2, E6; PROOF_OBLIGATIONS PO-1 and PO-3.

## F-002: issue text overstates `copy.copy()` relative to this checkout

Input: `copy.copy()` on `Dataset`, `DataArray`, `Variable`, or `IndexVariable`
in this source tree.

Observed in source: each `__copy__` method delegates to `copy(deep=False)`.
The public hint also says `DataArray.copy(deep=False)` is not affected.

Expected: shallow copies still preserve dtype, but no source change to
`__copy__` is justified by the audited code path.

Classification: public-text/code mismatch; no code change required.

Resolution: keep V1 unchanged for shallow copy. The shallow branch reuses the
existing adapter, so adapter dtype is preserved.

Trace: SPEC E4; PROOF_OBLIGATIONS PO-2 and PO-6.

## F-003: proof is constructed only

Input: the supporting K files and claims in `fvk/mini-xarray-copy.k` and
`fvk/xarray-copy-spec.k`.

Observed: no K tooling was run, per the task constraints.

Expected: artifacts include exact commands and remain labeled constructed, not
machine-checked. No tests are removed or modified.

Classification: proof-status limitation, not a code bug.

Resolution: keep tests fixed and hidden; record the commands in `PROOF.md`.

Trace: PROOF_OBLIGATIONS PO-8.

## Audit Verdict

No open code findings remain. V1 satisfies the dtype-preservation obligations
identified by the public issue and the proof obligations, so no additional
source edit is justified.
