# FVK Findings

Constructed, not machine-checked. No tests or project code were executed.

## F1: V1 prevented duplicate-code reports at the computation boundary

Input: a `Similar` or `SimilarChecker` state with `min_lines = 0` and any files,
including files with duplicate code.

Observed in V1: `_compute_sims()` returned `[]` before pair matching.

Expected from E1-E4: no duplicate-code findings are produced.

Verdict: discharged by PROOF_OBLIGATIONS PO3 and PO4. Keep the V1
`_compute_sims()` guard.

## F2: V1 still collected module data in pylint's raw-checker path

Input: pylint run with rcfile `min-similarity-lines=0`.

Observed in V1: `SimilarChecker.process_module()` still opened each module stream
and called `append_stream()`, building `LineSet` data that could only be discarded
later by `_compute_sims()`.

Expected from E1, E4, and E7: the duplicate-code check is disabled, so the
checker should avoid local duplicate-code collection work when the disabled
sentinel is active.

Verdict: code bug / needed guard. V2 adds the `process_module()` early return.
Discharged by PROOF_OBLIGATIONS PO2.

## F3: Positive thresholds must remain unchanged

Input: any run with `min_lines > 0`.

Observed in V2: both new guards are false, so the previous collection and
similarity code paths are reached.

Expected from E4: only the disabled sentinel changes behavior.

Verdict: discharged by PROOF_OBLIGATIONS PO6.

## F4: Negative thresholds are underspecified

Input: `min_lines < 0`.

Observed in V2: treated as disabled because the guards use `<= 0`.

Expected from public intent: only `0` is specified. A negative minimum line count
has no meaningful threshold interpretation.

Verdict: accepted default-domain assumption, not a public requirement. If future
intent wants stricter validation, add an option-value error for negatives.

## F5: Proof status is constructed only

Input: the FVK proof package.

Observed: K commands are recorded but not run, per task constraints.

Expected from FVK honesty gate: label the proof constructed, not
machine-checked, and do not remove tests.

Verdict: no source change needed. Keep existing tests; add focused tests in a
normal development environment.
