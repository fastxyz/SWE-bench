# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged. The FVK audit found no source defect requiring a V2 code
edit.

## Why V1 Stands

- `FINDINGS.md` F-001 and `PROOF_OBLIGATIONS.md` PO-005 show that V1 fixes the
  issue's operative defect: multi-required-column failures now display the full
  required prefix and found prefix.
- `FINDINGS.md` F-002 and `PROOF_OBLIGATIONS.md` PO-001 through PO-006 show that
  V1 preserves the original validity predicate and success behavior.
- `FINDINGS.md` F-003 and `PROOF_OBLIGATIONS.md` PO-004, PO-008 justify keeping
  the single-column scalar wording instead of applying a broader message-format
  refactor.
- `FINDINGS.md` F-004 confirms that the same multi-column logic covers the
  built-in `BinnedTimeSeries` required-prefix family.

## Recommended Follow-Up When Execution Is Available

1. Add or run a focused test for a `TimeSeries` with
   `_required_columns == ['time', 'flux']` after removing `flux`; the expected
   message should include both `['time', 'flux']` and `['time']`.
2. Add or run a focused test for `BinnedTimeSeries` losing or misordering
   `time_bin_size`, to cover the built-in multi-column required-prefix case.
3. Run the normal Astropy test path for `astropy/timeseries` once an execution
   environment is available.
4. If maintainers want a standalone FVK machine check, run the commands listed
   in `PROOF.md` against `fvk/mini-required-columns.k` and
   `fvk/required-columns-spec.k`.

## Rejected Next Changes

- Do not convert all single-column messages to list-shaped wording. The issue
  does not require it, and public tests document the scalar message as current
  compatibility behavior.
- Do not refactor `_check_required_columns()` into helper functions in this
  patch. The existing change is localized and the proof obligations are already
  straightforward.
- Do not edit tests in this benchmark task. The task explicitly forbids test
  modifications.
