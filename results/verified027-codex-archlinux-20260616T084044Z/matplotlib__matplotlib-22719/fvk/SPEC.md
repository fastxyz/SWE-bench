# FVK Spec

Status: constructed, not machine-checked. The proof commands are recorded in
`PROOF.md` and must not be treated as executed in this workspace.

## Scope

This audit targets the V1 production-code changes in
`repo/lib/matplotlib/category.py`:

- `StrCategoryConverter.convert`
- `UnitData.update`

The formal model abstracts NumPy normalization to a normalized data size `N`
and summary predicates. This is intentional: the reported defect is branch
selection caused by vacuous truth on empty data, so the proof must preserve
`N == 0` versus `N > 0` and the warning/log observables. Full NumPy shape
semantics, mapping insertion order, and drawing integration are outside the
formal core and remain covered by unchanged source behavior and public tests.

## Intent Ledger

Critical public evidence is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

- E1/E3 require empty data to be an in-domain, successful no-data conversion
  after category units are established.
- E2 marks the empty-data deprecation warning as the bug symptom, so it is
  SUSPECT legacy behavior and cannot be preserved as a contract.
- E4 requires a converter-level fix because direct `ax.convert_xunits([])` also
  reaches the warning path.
- E5/E6 provide public patch-shape evidence that both vacuous `all(...)` checks
  should be guarded by non-empty data.
- E7/E8/E9 are frame conditions: non-empty numeric pass-through warnings,
  non-empty mixed-type failures, and category mapping order must remain.

## Abstract Domains

For `StrCategoryConverter.convert`:

- `N`: `values.size` after `np.atleast_1d(np.array(value, dtype=object))`.
- `AllNumlike`: result of the existing `all(is_numlike(v) and not
  isinstance(v, (str, bytes)) for v in values)` summary. For `N == 0`, this can
  be true by vacuous truth.
- `UpdateAccepts`: whether `UnitData.update(values)` accepts all elements as
  strings/bytes. For `N == 0`, this is true because there are no elements to
  reject.

For `UnitData.update`:

- `N`: `data.size` after normalization.
- `AllConvertible`: whether every inspected value is parseable as float/date.
  For `N == 0`, this can be true by vacuous truth.

## Functional Contracts

S1. Empty conversion contract:
If `N == 0`, the unit object is valid, and update accepts the empty value set,
then `StrCategoryConverter.convert` must return an empty converted result and
must not emit the numeric pass-through deprecation warning, even when
`AllNumlike` is vacuously true.

S2. Non-empty numeric pass-through frame:
If `N > 0` and `AllNumlike` is true, conversion emits the existing
`MatplotlibDeprecationWarning` and returns numeric values of size `N`.

S3. Non-empty categorical conversion frame:
If `N > 0`, `AllNumlike` is false, and `UpdateAccepts` is true, conversion must
not emit the numeric pass-through deprecation warning and returns mapped values
of size `N`.

S4. Non-empty invalid categorical frame:
If `N > 0`, `AllNumlike` is false, and `UpdateAccepts` is false, conversion
must continue to fail through `UnitData.update` validation rather than being
silently treated as numeric or empty.

S5. Empty update log contract:
If `N == 0`, `UnitData.update` must not emit the "all parseable as floats or
dates" informational log, even when `AllConvertible` remains true by vacuity.

S6. Non-empty all-convertible update frame:
If `N > 0` and `AllConvertible` is true, `UnitData.update` may emit the existing
informational log and must preserve mapping update behavior.

S7. Compatibility frame:
No public signatures, virtual dispatch call shapes, or converter registry
entries change.

## Formal Artifacts

- `mini-category.k` defines the minimal warning/log/status semantics used here.
- `category-empty-spec.k` contains K claims for S1-S6 with provenance comments.
- `FORMAL_SPEC_ENGLISH.md` paraphrases those claims.
- `SPEC_AUDIT.md` checks the formal English against this intent spec.
- `PUBLIC_COMPATIBILITY_AUDIT.md` checks S7.
