# FVK Findings

Status: constructed, not machine-checked.

## F1: Baseline regression mechanism

Input: a Django template backend whose configured `DIRS` contains `""`.

Observed in the pre-fix code: `get_template_directories()` applies
`cwd / to_path("")`; `to_path("")` creates `Path(".")`, so the result includes
`Path.cwd()`.

Expected from public intent: the empty string should behave like the previous
non-match for autoreload purposes and must not introduce `Path.cwd()`.

Classification: code bug in the pre-fix implementation.

Covered by: PO1, PO5, C1, C3.

Resolution in V1: fixed.

## F2: Loader path reintroduction

Input: a filesystem loader whose `get_dirs()` returns `engine.dirs`, where
`engine.dirs` contains `""`.

Observed in the pre-fix code: even if direct configured dirs were filtered, the
loader loop could re-add `cwd / to_path("")` unless it applied the same empty
string check.

Expected from public intent: all contributors to the template directory set must
avoid introducing `Path.cwd()` from `""`.

Classification: completeness risk for any one-sided fix.

Covered by: PO2, PO5, C2, C3.

Resolution in V1: fixed.

## F3: Over-broad falsey filtering would change behavior

Input: explicit current-directory configuration such as `"."` or `Path(".")`.

Observed with an over-broad fix such as `if directory`: some values could be
silently skipped or invalid values such as `None` could stop surfacing through
the existing validation path.

Expected from public intent: only the exact empty string is identified as the
regression source. Non-empty relative path normalization remains intended.

Classification: rejected alternative, compatibility risk.

Covered by: PO3, PO4, PO6, C4, C5.

Resolution in V1: avoided.

## Proof-derived findings from `/verify`

No unresolved proof-derived code bug was found. The constructed proof obligations
close over the intended slice: direct dirs, loader dirs, preservation of
non-empty values, and the `template_changed()` false-positive symptom.

Residual risk: the K artifacts were not machine-checked, and the model abstracts
Django engine discovery into finite source lists. This is an artifact trust-base
limitation, not a current code finding.

