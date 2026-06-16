# Constructed Proof

Status: constructed, not machine-checked. The benchmark instructions forbid running tests, Python, `kompile`, or `kprove`.

## Claims Proved on Paper

C-001: `polylog(2, S.Half)` evaluates to `pi**2/12 - log(2)**2/2`.

C-002: `expand_func(polylog(1, z))` expands to `-log(1 - z)`.

C-003: `lerchphi` rational-argument expansion routes each generated `polylog` subterm through `expand_func(..., deep=False)`, so evaluated subterms remain valid expressions.

## Symbolic Execution Sketch

For C-001, start in `polylog.eval(s=2, z=S.Half)`. The first three guards compare `z` with `1`, `-1`, and `0`; none match. The new guard `s == 2 and z == S.Half` matches and returns the closed form. This discharges PO-001.

For C-002, start in `polylog._eval_expand_func` with `s == 1`. The first branch returns `-log(1 - z)`. The removed imports `exp_polar` and `I` are no longer available in this method, so the old polarized expression cannot be constructed by this branch. This discharges PO-002.

For C-003, start in `lerchphi._eval_expand_func` on the rational-`a` branch. Each term formerly evaluated `polylog(s, zet**k*root)` and immediately called the private `_eval_expand_func` method on the result. After PO-001, that result can be a normal expression. V2 instead applies `expand_func(polylog(...), deep=False)`, whose public contract accepts both unevaluated functions and already-evaluated expressions. This discharges PO-003 while preserving top-level-only expansion behavior.

## Residual Risk

The proof uses a mini term-rewrite abstraction, not full Python or full SymPy semantics. It is adequate for the issue's observable expression rewrites but does not prove unrelated canonicalization, simplification, numeric evaluation, or termination properties.

No machine check was run. The exact commands for a future human/tooling pass are:

```sh
kompile fvk/mini-sympy-polylog.k --backend haskell
kast --backend haskell fvk/polylog-spec.k
kprove fvk/polylog-spec.k --backend haskell
```

Expected machine-check result after adapting paths/module options as needed: `#Top`.

## Test Recommendations

Do not remove tests unless the K claims are machine-checked. Existing tests that assert the old `exp_polar` expansion or comment that the `1/2` value is unknown are stale relative to the public issue and should be updated by the normal test-maintenance process, but this task forbids editing tests.

Suggested future tests:

- `polylog(2, S.Half) == pi**2/12 - log(2)**2/2`
- `expand_func(polylog(1, z)) == -log(1 - z)`
- a `lerchphi` rational-argument expansion path whose generated polylog subterm evaluates before expansion, to guard F-003.
