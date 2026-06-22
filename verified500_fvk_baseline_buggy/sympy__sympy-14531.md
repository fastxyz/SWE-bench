# sympy__sympy-14531

- **Verdict:** B_COMPLETENESS — baseline fixed only the two printer methods named in the issue (`Limit`, `Relational`); fvk extended the identical one-line fix to the other seven `StrPrinter` methods carrying the same latent bug, so `sympy_integers=True` is now honored everywhere it was being silently dropped.
- **Pitch-worthiness (1-5):** 4 — clean, runnable "passed the tests but still wrong" story: same setting, asked-for behavior, baseline prints `Interval(1/2, 3/2)` (lossy float on re-parse) while fvk prints `Interval(S(1)/2, S(3)/2)` (exact). Held off 5 only because the symptom is print/round-trip fidelity, which needs one sentence of framing for a non-expert.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
SymPy's string printer has a `sympy_integers=True` option making output round-trip-safe: integers print as `S(1)/2` (exact `Rational`) not `1/2` (re-parses to Python float `0.5`). Bug: several printer methods built output by interpolating raw subexpressions with `%s` (plain `str()`), bypassing the active printer and dropping the setting. The issue shows `Eq` and `Limit` losing it; the same defect lurks in many sibling methods.

## What baseline did
Correctly diagnosed the root cause but fixed exactly the two methods named in the issue: `_print_Limit` and the equality branch of `_print_Relational`. Its notes say it "considered broadly replacing every direct `%s` interpolation ... but rejected that as too large." Every other method with the identical bug was left broken.

## What fvk changed and why
Kept baseline's two fixes and routed operand fields of seven more methods through `self._print(...)`: `_print_AppliedPredicate`, `_print_ExprCondPair` (Piecewise), `_print_Interval`, `_print_Lambda`, `_print_MatrixElement`, `_print_Normal`, `_print_Uniform` — the same latent bug. It explicitly bounded the change and left domain-specific delegating methods alone.

## Concrete demonstration
Built baseline- and fvk-patched copies of `str.py` from a version-identical base (`sympy__sympy-14248/repo`, whose pre-patch `str.py` is byte-identical to 14531's base — both patches apply with `git apply --check`), ran on Python 3.9 / sympy 1.1.2.dev. All inputs `sstr(..., sympy_integers=True)`:

| Input | baseline (WRONG) | fvk (RIGHT) = expected |
|---|---|---|
| `Interval(S(1)/2, S(3)/2)` | `Interval(1/2, 3/2)` | `Interval(S(1)/2, S(3)/2)` |
| `Lambda(x, S(1)/2)` | `Lambda(x, 1/2)` | `Lambda(x, S(1)/2)` |
| `Piecewise((S(1)/2, x>0),(S(1)/3,True))` | `Piecewise((1/2, x > 0), (1/3, True))` | `Piecewise((S(1)/2, x > S(0)), (S(1)/3, True))` |
| `Q.positive(x + S(1)/2)` | `Q.positive(x + 1/2)` | `Q.positive(x + S(1)/2)` |

Why wrong, not cosmetic: the point of the setting is round-trip safety. Re-evaluated as Python, baseline's `Interval(1/2, 3/2)` gives float endpoints (`eval('1/2')==0.5`), losing exactness; fvk's re-parses to exact `Rational`. Code: baseline `_print_Interval` ends `fin.format(**{'a': a, 'b': b, 'm': m})` (raw `a`/`b`); fvk uses `'a': self._print(a), 'b': self._print(b)`. Same in `_print_Lambda` (`% (args.args[0], expr)` vs `% (self._print(...), self._print(expr))`). No regression: with default settings both print identically; divergence appears only when the setting is on.

## Why the tests missed it
`FAIL_TO_PASS` is only `test_Rational` + `test_python_relational`, and `gold_test.patch` adds asserts only for `Eq(x, S(2)/3)`, `Limit(x, x, S(7)/2)`, `python(Eq(x,y))` — i.e. only the two methods baseline already fixed. No test exercises Interval/Lambda/Piecewise/AppliedPredicate/Normal/Uniform/MatrixElement under `sympy_integers=True`. Both `FAIL_TO_PASS` tests pass against each variant (2 passed). The suite is provably blind to the defect.

## FVK vs. Human Fix

**Human fix issue:** partial.

The human fix and FVK share the core recursive-printing insight: nested SymPy operands must go through `self._print(...)`. Gold covers some additional domain printers; FVK covers `Interval`, which gold missed.

Strong match. The human gold patch routes operands through `self._print(...)` in exactly the methods fvk extended: confirmed gold modifies `_print_AppliedPredicate`, `_print_ExprCondPair`, `_print_Lambda`, `_print_MatrixElement`, `_print_Normal`, `_print_Uniform` (+ Limit/Relational). E.g. gold `return "Lambda(%s, %s)" % (self._print(args.args[0]), self._print(expr))` — identical to fvk. Two minor divergences: gold also fixed some domain methods fvk left (`_print_Permutation`, `_print_PolyRing`, `_print_FracField`, `_print_Pi`, `_print_TensAdd`); and gold did NOT fix `_print_Interval` but fvk did — a legitimate fix, so on Interval fvk is *more complete than the human*. **GOLD_MATCH: yes.**

## Confidence & caveats
High. Demonstration is reproducible; outputs are real program output, not from notes. Base file byte-identical to 14531's. Caveats: ran on a version-equivalent sibling repo (only `str.py` matters, matches exactly); two unrelated tests fail identically on baseline AND fvk and are not in 14531's PASS_TO_PASS — pre-existing version noise, not an fvk regression. All PASS_TO_PASS tests touching fvk's extended methods (test_Interval, test_Lambda, test_Limit, test_Relational, test_RandomDomain) pass on fvk.
