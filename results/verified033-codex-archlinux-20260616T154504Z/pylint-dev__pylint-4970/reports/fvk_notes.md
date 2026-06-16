# FVK Notes

## Source changes from the FVK audit

`repo/pylint/checkers/similar.py`

- Kept the V1 `_compute_sims()` guard. `fvk/FINDINGS.md` F1 and
  `fvk/PROOF_OBLIGATIONS.md` PO3 show this is the shared behavioral backstop:
  direct `Similar` use, standalone `symilar`, serial pylint close, and parallel
  reduce all get an empty similarity list when `min_lines <= 0`.
- Added the V2 `SimilarChecker.process_module()` guard. F2 identified that V1
  still collected module streams and built `LineSet` data even when the public
  intent says duplicate-code checking is disabled. PO2 is now discharged because
  the method returns before opening the stream or calling `append_stream()`.
- Kept the option help text from V1. PO8 records that documenting `0` as the
  disable sentinel is part of the user-facing contract.

## Decisions to keep behavior unchanged

- Positive thresholds were left unchanged. F3 and PO6 show both new guards are
  false for `min_lines > 0`, so the original collection and similarity algorithm
  still run.
- I did not change checker registration or broader linter scheduling. The FVK
  scope in `fvk/SPEC.md` and `fvk/ITERATION_GUIDANCE.md` shows the issue can be
  discharged locally without changing public checker APIs or scheduling behavior.
- I kept `<= 0` rather than narrowing to `== 0`. F4 records that negatives are
  underspecified by public intent, but a negative minimum line count is not
  meaningful; treating non-positive values as disabled is a documented
  default-domain assumption.

## Verification status

The FVK proof is constructed, not machine-checked. Per F5, I did not run tests,
Python, `kompile`, `kast`, or `kprove`; the commands are recorded in
`fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a later execution-capable
environment. No test files were modified.
