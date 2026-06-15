# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-001: Active Required Prefix Selection

Claim references: RC-MISMATCH-SINGLE, RC-MISMATCH-MULTI, RC-VALID.

Obligation: if `_required_columns_relax` is true, the active required list is
`_required_columns[:len(self.colnames)]`; otherwise it is `_required_columns`.

Source evidence: `SPEC.md` I3 and E8.

Discharge: V1 preserves the exact existing assignment:
`required_columns = self._required_columns[:len(self.colnames)]` in relaxed
mode and `required_columns = self._required_columns` otherwise.

Status: discharged by source inspection.

## PO-002: Disabled and Absent Required-Column Contracts Are No-Ops

Claim references: RC-DISABLED, RC-NONE.

Obligation: return without raising when `_required_columns_enabled` is false, or
when `_required_columns` is `None`.

Source evidence: `SPEC.md` I1-I2.

Discharge: V1 did not alter the early return for disabled checks or the guard
around `_required_columns is not None`.

Status: discharged by source inspection.

## PO-003: Non-Relaxed Empty Column Failure

Claim references: RC-NONRELAX-EMPTY-SINGLE, RC-NONRELAX-EMPTY-MULTI.

Obligation: outside relaxed mode, an object with no columns violates a non-empty
required-column contract. Single-column requirements keep scalar wording; multi-
column requirements report the list-shaped required prefix.

Source evidence: `SPEC.md` I4-I6.

Discharge: V1 branches on `len(required_columns) == 1` in the no-columns path.
The one-column branch keeps `expected '<name>' as the first column...`; the
multi-column branch uses `required {required_columns} as the first columns...`.

Status: discharged by source inspection.

## PO-004: Single-Column Prefix Mismatch Message

Claim reference: RC-MISMATCH-SINGLE.

Obligation: if the active required prefix length is one and the found prefix is
different, raise the legacy scalar message.

Source evidence: `SPEC.md` I6 and E10; `FINDINGS.md` F-003.

Discharge: V1 branches on `len(required_columns) == 1` and formats
`required_columns[0]` and `self.colnames[0]`, preserving the public assertions
for standard `TimeSeries` failures.

Status: discharged by source inspection.

## PO-005: Multi-Column Prefix Mismatch Message

Claim reference: RC-MISMATCH-MULTI.

Obligation: if the active required prefix length is greater than one and the
found prefix differs, raise an exception whose message contains the complete
active required list and `self.colnames[:len(required_columns)]`.

Source evidence: `SPEC.md` I5 and E1-E6; `FINDINGS.md` F-001 and F-004.

Discharge: V1's multi-column mismatch branch formats `required_columns` and
`self.colnames[:len(required_columns)]`, so for the reproduction state
`req == ['time', 'flux']` and `cols == ['time']`, the found part is `['time']`
instead of scalar `'time'`.

Status: discharged by source inspection.

## PO-006: Valid Prefix Preserves Normal Return and Relax Toggle

Claim reference: RC-VALID.

Obligation: when the active required prefix matches the current column prefix,
the method must not raise; if relaxed mode now has the full required prefix, it
must set `_required_columns_relax` to false.

Source evidence: `SPEC.md` I3 and I7.

Discharge: V1 did not alter the existing success path or relax-toggle predicate
`self._required_columns == self.colnames[:len(self._required_columns)]`.

Status: discharged by source inspection.

## PO-007: Mutating Methods Still Invoke the Check

Claim references: all check claims, via public call path.

Obligation: column-mutating methods remain wrapped so the required-column check
runs after mutations such as `remove_column("flux")`.

Source evidence: issue reproduction and `SPEC.md` E2, E7.

Discharge: V1 did not alter `COLUMN_RELATED_METHODS`, `autocheck_required_columns`,
or the wrapper that calls `self._check_required_columns()` after the mutation.

Status: discharged by source inspection.

## PO-008: Public Compatibility

Claim references: adequacy audit A4.

Obligation: the fix must not change public signatures, method dispatch shape, or
valid-object behavior outside the intended message improvement.

Source evidence: `SPEC.md` I6, E9-E10; `FINDINGS.md` F-003.

Discharge: V1 changes only exception message formatting inside
`_check_required_columns()`. It adds no parameters, changes no return value, and
does not modify test files.

Status: discharged by source inspection.

## PO-009: Honesty Gate

Claim references: all claims.

Obligation: because the task forbids execution, artifacts must state that proof
and verification are constructed, not machine-checked, and no test deletion can
be justified.

Source evidence: task no-execution rule and FVK verify honesty gate.

Discharge: `SPEC.md`, `FINDINGS.md`, and `PROOF.md` carry the constructed/not
machine-checked label, and `ITERATION_GUIDANCE.md` recommends keeping tests
until real tool/test execution is allowed.

Status: discharged by artifact inspection.
