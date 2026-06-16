# Findings

Status: constructed, not machine-checked.

## F-001: Original numeric `has_key` RHS defect

Classification: code bug, fixed.

Evidence: E-001 through E-004; PO-001 and PO-003.

Input: `data = {"1111": "bar"}` with `filter(data__has_key="1111")` on
SQLite, MySQL, or Oracle.

Observed in V0: the path-based compiler used ordinary `compile_json_path()` for
the RHS key, so `"1111"` became array index `[1111]`; the row was not found.

Expected: `"1111"` is a JSON object member name; the generated path must use a
member component for the final lookup key.

Resolution: V2 keeps V1's `compile_json_path_final_key()` for actual
`has_key`-style RHS paths.

## F-002: V1 over-applied final-key semantics to internal transform checks

Classification: V1 regression found by FVK audit, fixed in V2.

Evidence: E-005 and E-006; PO-002 and PO-004.

Input: `value = {"d": ["e"]}` with `filter(value__d__0__isnull=False)` on
SQLite or the analogous Oracle transform-existence path.

Observed in V1 by static reasoning: `KeyTransformIsNull` internally calls
`HasKey(self.lhs.lhs, self.lhs.key_name)`. With V1's unconditional final-key
compiler, the final transform segment `"0"` would compile as object member
`."0"` instead of array index `[0]`.

Expected: `__isnull` on a `KeyTransform` preserves normal transform semantics;
numeric transform segments remain array indexes.

Resolution: V2 adds a defaulted `final_key` flag to `HasKeyLookup.as_sql()` and
`as_oracle()`. Actual lookup RHS paths use `final_key=True`; internal
`KeyTransformIsNull` and `KeyTransformExact.as_oracle` callers pass
`final_key=False`.

## F-003: Proof is constructed only

Classification: proof-status caveat, not a code bug.

Evidence: FVK documentation and task constraints forbid running K tooling.

Observed: `.k` artifacts and proof obligations are written, but `kompile`,
`kast`, and `kprove` were not executed.

Expected: treat the proof as constructed, not machine-checked. Do not remove or
modify tests based on this proof alone.

Resolution: commands are recorded in `PROOF.md` for later machine checking.
