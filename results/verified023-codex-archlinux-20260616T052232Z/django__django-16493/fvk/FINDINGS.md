# FINDINGS

Status: constructed for audit; not machine-checked.

## FVK-F1 - V0 root cause: evaluated storage controlled omission

Classification: code bug in the pre-V1 implementation.

Input: `FileField(storage=get_storage)` where `get_storage()` returns
`default_storage`.

Observed pre-V1 behavior: `deconstruct()` omitted `kwargs["storage"]` because it
compared evaluated `self.storage` with `default_storage`.

Expected behavior: `deconstruct()` includes `kwargs["storage"] = get_storage`
because the original field argument was a callable and migrations must recreate
that callable storage provider.

Evidence: ledger entries E1-E6. Proof obligations: O2 and O5.

## FVK-F2 - V1 discharges callable returning default_storage

Classification: fixed/confirmed.

Input: `FileField(storage=get_storage)` where `get_storage()` returns
`default_storage`.

V1 behavior by symbolic inspection: `storage =
getattr(self, "_storage_callable", self.storage)` selects `get_storage`, so
`storage is not default_storage` is true and `kwargs["storage"]` is set to the
callable.

Expected behavior: same as V1.

Evidence: ledger entries E2, E5, E6, E10, E11. Proof obligation: O2. Formal
claim: `CALLABLE-DEFAULT`.

## FVK-F3 - V1 preserves implicit/default omission

Classification: fixed/confirmed.

Input: `FileField()` or direct `FileField(storage=default_storage)`.

V1 behavior by symbolic inspection: `_storage_callable` is absent, selected
storage is `default_storage`, and `kwargs["storage"]` is omitted.

Expected behavior: default-value omission remains allowed.

Evidence: ledger entries E7, E8. Proof obligation: O3. Formal claims:
`DEFAULT-IMPLICIT`, `DIRECT-DEFAULT`.

## FVK-F4 - V1 preserves direct and callable non-default serialization

Classification: fixed/confirmed.

Input A: `FileField(storage=other_storage)`.

V1 behavior by symbolic inspection: selected storage is `other_storage`; kwargs
include the direct storage object.

Input B: `FileField(storage=get_storage)` where `get_storage()` returns
`other_storage`.

V1 behavior by symbolic inspection: selected storage is `_storage_callable`;
kwargs include the callable.

Expected behavior: same as V1.

Evidence: ledger entries E7-E9. Proof obligations: O4 and O5. Formal claims:
`DIRECT-OTHER`, `CALLABLE-OTHER`.

## FVK-F5 - No additional source change justified

Classification: no remaining code bug found in audited scope.

The V1 edit uses the same selected value for both the default comparison and
the serialized `storage` kwarg. This matches the issue hint exactly and
discharges all storage-deconstruction cases in the intent domain. The audit did
not identify an uncovered public branch requiring another production-code edit.

Evidence: FVK-F2 through FVK-F4. Proof obligations: O2 through O6.

## Residual risk

The proof is constructed, not machine-checked. No tests, Python, or K tooling
were executed. The K model is a finite abstraction of `FileField` storage
deconstruction and does not prove unrelated `FileField` behavior.
