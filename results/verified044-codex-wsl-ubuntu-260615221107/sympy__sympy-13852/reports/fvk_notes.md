# FVK Notes

## Decisions

V1's `polylog(2, S.Half)` construction-path evaluation stands. This is justified by F-001 and PO-001: the issue shows the bare expression remaining unevaluated and names the closed form as the answer.

V1's `polylog(1, z)` expansion change stands. This is justified by F-002 and PO-002: the issue explicitly rejects `exp_polar(-I*pi)` in this expansion and identifies `-log(1 - z)` as the intended identity.

V2 adds one source change in `lerchphi._eval_expand_func`: the rational-`a` polylog subterm now uses `expand_func(polylog(...), deep=False)` instead of calling `_eval_expand_func` directly. This is justified by F-003 and PO-003. Once PO-001 makes `polylog(2, S.Half)` evaluate to an `Add`, a direct private-method call on the result is not safe; the public helper preserves the intended top-level function expansion and accepts already-evaluated expressions.

I did not broaden automatic `polylog` evaluation beyond `polylog(2, S.Half)`. This is justified by F-005 and PO-004: the local docstring distinguishes automatic special `z` values from opt-in symbolic `expand_func` identities, and the issue supplies one concrete missing value rather than a derivable broader table.

I did not modify tests. This is justified by F-004 and PO-005: public tests/comments that encode the old behavior are SUSPECT under FVK, but the benchmark explicitly forbids test-file edits.

I did not run tests, Python, or K tooling. This is justified by F-006 and PO-005. The K commands are recorded in `fvk/PROOF.md` for a later machine-checking pass.

## Changed Files

`repo/sympy/functions/special/zeta_functions.py`

- Kept V1's `polylog.eval` branch for `s == 2 and z == S.Half`.
- Kept V1's `polylog._eval_expand_func` branch returning `-log(1 - z)` for `s == 1`.
- Added V2's `expand_func(..., deep=False)` call in the `lerchphi` rational-`a` branch.

`fvk/`

- Added the required FVK artifacts and a small constructed formal core.

`reports/fvk_notes.md`

- Added this trace from decisions to findings and proof obligations.
