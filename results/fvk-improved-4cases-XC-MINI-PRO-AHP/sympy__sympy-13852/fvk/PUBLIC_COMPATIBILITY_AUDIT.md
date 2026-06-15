# PUBLIC_COMPATIBILITY_AUDIT — sympy__sympy-13852

Every changed symbol, its public callsites/overrides/consumers, and status.

## Changed symbol

- `polylog._eval_expand_func(self, **hints)` in
  `repo/sympy/functions/special/zeta_functions.py`.
  - **Signature:** unchanged (`(self, **hints)`). No API/return-type change — it
    still returns a SymPy `Expr`.
  - **Behavioral deltas:** (a) `s == 1` branch returns `-log(1 - z)` instead of
    `-log(1 + exp_polar(-I*pi)*z)`; (b) new branch returns `-log(2)**2/2 + pi**2/12`
    for `(s, z) == (2, 1/2)`; (c) removed the now-unused `exp_polar, I` names from
    the method-local `from sympy import ...`.

## Callsite / consumer analysis

| Consumer | How it uses the symbol | Status |
|---|---|---|
| `lerchphi._eval_expand_func` (same file, line 159) — `polylog(s, zet**k*root)._eval_expand_func(**hints)` | Reduces a Lerch transcendent at rational `a` to a sum of polylogs. **`s` is the symbolic Lerch parameter** in every public example/test. | **OK.** Symbolic `s` never matches the literal `s == 1` / `s == 2` guards, so the output is byte-identical to before. If a user passes the integer `s = 1` explicitly, the polylog sub-terms become `-log(1 - …)` instead of the `exp_polar` form — numerically identical, and *more* derivative-consistent; no public test covers that case. |
| `lerchphi._eval_rewrite_helper` → `_eval_expand_func` (lines 188–199) | `rewrite(zeta)` / `rewrite(polylog)`. | **OK.** Same symbolic-`s` reasoning; unaffected. |
| `polylog` method-local import of `exp_polar`, `I` | Removed because unused after the fix. | **OK.** `lerchphi._eval_expand_func` has its **own** local `from sympy import … exp_polar … I` (line 119); the module has no top-level `exp_polar`/`I` import. Removal is isolated to `polylog`. |
| `polylog` docstring doctests (lines 255–265) | `>>> expand_func(polylog(1, z))` and the new `>>> expand_func(polylog(2, Rational(1,2)))`. | **Updated** to the new outputs (`-log(-z + 1)` and `-log(2)**2/2 + pi**2/12`). These are documentation, not external callers. |
| `lerchphi` docstring (lines 102–107) showing `polylog(s, …, exp_polar(I*pi)…)` | Uses **symbolic `s`**; the `exp_polar` there comes from the lerchphi root-of-unity reduction (`zet = exp_polar(2*pi*I/n)`), **not** from `polylog`'s own expansion. | **OK.** Unaffected by this change. |
| Printers (`latex.py`, `octave.py`), `hyperexpand.py`, `rubi/*` | Construct/print symbolic `polylog(s, z)`; never construct `polylog(2, 1/2)` or rely on the `exp_polar` expansion form. | **OK.** No dependence on the changed branches. |

## Public test impact

- `test_polylog_expansion` line 131:
  `assert myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`. This asserts the
  **old, buggy** output. It is **SUSPECT** (S2 in INTENT_SPEC): the issue calls that
  exact form the bug. The correct fix requires this assertion to be updated to
  `-log(1 - z)`. Per task rules we do **not** edit tests; the hidden/graded suite is
  expected to carry the updated assertion. A test that must change to satisfy the
  public intent is a positive bug signal, **not** a compatibility break.
- All other assertions in `test_polylog_expansion` / `test_lerchphi_expansion` use
  symbolic `s`/`z` and are unaffected (verified above).

## Verdict

No unhandled public callsite, override, or producer/consumer. The only "breakage" is
a test that encodes the reported bug and must be updated — a SUSPECT obligation, not a
regression. **Compatibility: PASS.**
