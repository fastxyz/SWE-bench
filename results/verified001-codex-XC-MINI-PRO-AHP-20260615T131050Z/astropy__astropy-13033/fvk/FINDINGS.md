# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Pre-Fix Multi-Required-Column Message Was Misleading

Classification: code bug fixed by V1.

Evidence: `SPEC.md` E1-E6 and `PROOF_OBLIGATIONS.md` PO-005.

Input class: `class_name == "TimeSeries"`, `enabled == True`,
`relax == False`, `req == ['time', 'flux']`, and post-mutation
`cols == ['time']`.

Observed before V1: the prefix check failed, but the message was formed from
only `req[0]` and `cols[0]`, producing the contradictory display
`expected 'time' as the first columns but found 'time'`.

Expected: the exception should report the complete required prefix and actual
found prefix, e.g. `required ['time', 'flux'] as the first columns but found
['time']`.

V1 status: fixed. The multi-column mismatch branch uses `required_columns` and
`self.colnames[:len(required_columns)]`.

## F-002: V1 Preserves the Required Prefix Contract

Classification: no code issue found.

Evidence: `SPEC.md` I3-I5 and `PROOF_OBLIGATIONS.md` PO-001, PO-004, PO-005.

Input class: any active required-column check with `_required_columns` not
`None`.

Observed in V1: the decision to raise still uses the original predicate
`self.colnames[:len(required_columns)] != required_columns`. V1 changes only the
message selected after that predicate fails.

Expected: the same invalid states should remain invalid, but multi-column
failures should identify the list-shaped required and found prefixes.

V1 status: confirmed.

## F-003: Single-Required-Column Wording Is a Compatibility Frame Condition

Classification: intentional no-change decision.

Evidence: `SPEC.md` E9-E10 and `PROOF_OBLIGATIONS.md` PO-004, PO-008.

Input class: `req` active length is one, including standard `TimeSeries`
failures and relaxed `BinnedTimeSeries` first-column failures.

Observed in V1: single-column failures keep the legacy scalar text, e.g.
`expected 'time' as the first column but found 'a'`.

Expected: because the issue targets additional required columns and public tests
assert the scalar strings exactly, preserving those messages is preferable to a
global list-format change.

V1 status: confirmed.

## F-004: Built-In Multi-Column Class Also Benefits

Classification: positive coverage note.

Evidence: `BinnedTimeSeries._required_columns == ['time_bin_start',
'time_bin_size']`, `SPEC.md` E9, and `PROOF_OBLIGATIONS.md` PO-005.

Input class: a `BinnedTimeSeries` object with a missing or wrong second required
column after mutation.

Observed in V1: the multi-column branch reports
`required ['time_bin_start', 'time_bin_size'] ... found [...]`, rather than
describing only `time_bin_start`.

Expected: the fix should apply to any additional required columns, not only the
custom `TimeSeries` reproduction.

V1 status: confirmed.

## F-005: Machine Check and Test Execution Are Intentionally Absent

Classification: proof-status caveat, not a code bug.

Evidence: task forbids running tests, Python, and K tooling;
`PROOF_OBLIGATIONS.md` PO-009.

Input class: all audited inputs.

Observed: the proof is constructed by inspection and symbolic case analysis, not
by `kprove`; no runtime tests were run.

Expected: artifacts must label the result as constructed, not machine-checked,
and must not recommend deleting tests.

V1 status: acceptable under this task's constraints.

## Proof-Derived Findings From `/verify`

No proof-derived source defect was found. The supporting `.k` artifacts were
written, but they were not parsed or proved because this task forbids K tooling.
The constructed commands in `PROOF.md` show the intended later machine-check
path.
