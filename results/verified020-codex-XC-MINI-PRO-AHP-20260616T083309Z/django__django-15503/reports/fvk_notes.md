# FVK Notes

## Decision summary

V1 did not stand unchanged. The FVK audit confirmed V1 fixed the reported
numeric `has_key` RHS defect (F-001, PO-001, PO-003), but found an over-broad
application of final-key semantics in internal `KeyTransform` existence checks
(F-002, PO-004). V2 keeps the V1 helper for actual `has_key`-style lookup RHS
values and adds an opt-out for internal transform-path callers.

## Source changes

`repo/django/db/models/fields/json.py`

- Kept `compile_json_path_final_key()` from V1 because F-001 and PO-001 require
  numeric-looking lookup RHS values such as `"1111"` to compile as object
  members.
- Changed `HasKeyLookup.as_sql()` to accept `final_key=True`. This preserves the
  actual lookup behavior required by PO-001 and PO-003 while making PO-004
  expressible for internal callers.
- Changed `HasKeyLookup.as_oracle()` to accept and forward `final_key=True` by
  default. This preserves existing public call compatibility while allowing the
  Oracle internal callers covered by F-002 to opt out.
- Updated `KeyTransformIsNull.as_oracle()` and `KeyTransformIsNull.as_sqlite()`
  to pass `final_key=False`. This directly addresses F-002: numeric final
  `KeyTransform` segments such as `0` remain array indexes for
  `value__d__0__isnull=False`.
- Updated `KeyTransformExact.as_oracle()` to pass `final_key=False` for its
  JSON-null existence check, for the same PO-004 reason.

## Rejected alternatives

I rejected reverting to V1 unchanged because F-002 showed a concrete public
behavior regression against `KeyTransform` numeric array-index semantics.

I rejected changing `compile_json_path()` globally because PO-002 and public
tests require numeric transform prefixes to remain array indexes.

I rejected duplicating the full `HasKey` SQL construction inside
`KeyTransformIsNull` because the smaller `final_key` flag keeps the SQL template
logic centralized and frames PO-005.

## Verification status

The FVK proof artifacts are constructed only. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`. The commands needed for a
future machine check are recorded in `fvk/PROOF.md`.
