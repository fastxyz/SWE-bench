# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 did not fully stand unchanged. FVK Finding F3 exposed a frame-condition issue introduced by the V1 broadening from long-only preprocessing to single-dash preprocessing: `-v` after `--` would be consumed as verbose. V2 keeps the V1 fixes for F1 and F2 and adds the separator guard required by PO4.

## Next Code State

Keep these V2 source changes:

- `repo/pylint/config/utils.py`: `-v` remains a preprocessable alias for verbose.
- `repo/pylint/config/utils.py`: `_preprocess_options` continues to inspect single-dash arguments, but stops at `--`.
- `repo/pylint/lint/base_options.py`: verbose keeps `kwargs={"nargs": 0}`.

No further production-code changes are justified by the scoped FVK findings.

## Suggested Tests For A Future Test-Editing Pass

Do not edit tests in this benchmark task. For a normal development pass, add or keep tests for:

- `pylint mytest.py -v` does not raise "expected one argument".
- `pylint --help` does not show a `VERBOSE` metavar for `--verbose` / `-v`.
- `-- -v` leaves `-v` after the separator unprocessed by the early preprocessor.

## Machine-Check Follow-Up

Run the commands listed in `fvk/PROOF.md` only in an environment where K execution is allowed. Until then, the proof remains constructed, not machine-checked.
