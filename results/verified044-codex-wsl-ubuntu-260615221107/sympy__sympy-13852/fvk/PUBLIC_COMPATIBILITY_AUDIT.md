# Public Compatibility Audit

Changed public symbol: `polylog`.

Compatibility result: pass. The function signature, class, and public import location are unchanged. The return value changes only for the public issue's concrete special value `polylog(2, S.Half)`.

Changed public behavior: `expand_func(polylog(1, z))`.

Compatibility result: intentional behavior change. Public issue text identifies the previous `exp_polar(-I*pi)` expression as the bug.

Internal caller audited: `lerchphi._eval_expand_func`.

Compatibility result: V2 patch required and applied. The caller now uses `expand_func(..., deep=False)` so it remains compatible with `polylog` calls that evaluate to non-`polylog` expressions.

Rubi helper `PolyLog`.

Compatibility result: pass. The helper delegates to `polylog(n, p)` and needs no signature or call-shape change.

Tests.

Compatibility result: not edited. Public tests/comments that encode old behavior are SUSPECT, but benchmark instructions forbid modifying test files.
