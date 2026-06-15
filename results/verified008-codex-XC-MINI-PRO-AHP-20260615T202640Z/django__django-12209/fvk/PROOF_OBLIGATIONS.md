# PROOF OBLIGATIONS

Status: constructed, not machine-checked. These obligations are the basis for confirming V1 unchanged.

## PO1 - Raw existing fixture row updates instead of inserting

Precondition:

- `Raw = true`
- `ForceInsertIn = false`
- `Adding = true`
- `HasPkDefault = true`
- `PkSet = true`
- `RowExists = true`

Postcondition:

- Observable outcome is `saved(true, update .Queries)`.
- No `insert` or `duplicate` query class is reached.

Source: Findings F1; intent ledger I1, I2, I3.

Status: discharged by the constructed proof.

## PO2 - Raw missing fixture row falls back to insert

Precondition:

- `Raw = true`
- `ForceInsertIn = false`
- `Adding = true`
- `HasPkDefault = true`
- `PkSet = true`
- `RowExists = false`

Postcondition:

- Observable outcome is `saved(false, update insert .Queries)`.

Source: Findings F2; intent ledger I1 and I3.

Status: discharged by the constructed proof.

## PO3 - Non-raw generated-default creation keeps the insert-only optimization

Precondition:

- `Raw = false`
- `ForceInsertIn = false`
- `Adding = true`
- `HasPkDefault = true`
- `PkSet = true`
- `RowExists = false`

Postcondition:

- Observable outcome is `saved(false, insert .Queries)`.
- UPDATE is not attempted.

Source: Findings F4; intent ledger I4 and I5.

Status: discharged by the constructed proof.

## PO4 - Direct non-raw explicit-pk compatibility is not proven

Precondition:

- `Raw = false`
- `ForceInsertIn = false`
- `Adding = true`
- `HasPkDefault = true`
- `PkSet = true`
- `RowExists = true`

Strong backward-compatible postcondition:

- Observable outcome would be `saved(true, update .Queries)`.

V1 behavior:

- Observable outcome is `saved(false, duplicate .Queries)` in the mini model.

Source: Finding F3; opening issue example and later public compromise.

Status: not discharged and intentionally not used to justify success. This is accepted as a residual limitation under the selected patch interpretation.

## PO5 - Public compatibility is preserved

Precondition:

- Source callers use the existing signatures of `save()`, `save_base()`, `DeserializedObject.save()`, and `_save_table()`.

Postcondition:

- No signature, dispatch, or serializer call protocol changes.
- `raw=True` from deserialization still reaches `_save_table()`.

Source: Finding F5; compatibility audit in `SPEC.md`.

Status: discharged by source inspection.

## PO6 - Honesty gate

Precondition:

- This benchmark forbids running tests, Python, `kompile`, or `kprove`.

Postcondition:

- Artifacts label the proof as constructed, not machine-checked.
- Commands needed for later machine checking are present.
- No test removal is recommended.

Status: discharged by artifact contents.
