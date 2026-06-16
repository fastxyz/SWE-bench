# FVK Specification: sympy__sympy-21379

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

The audited unit is `Mod.eval` in `repo/sympy/core/mod.py`, specifically the
best-effort common-factor extraction:

```python
G = gcd(p, q)
if G != 1:
    p, q = [gcd_terms(i/G, clear=False, fraction=False) for i in (p, q)]
```

The public issue traces the user-visible `subs` failure to this block through
`sinh._eval_is_real`, which evaluates `im % pi` and therefore constructs `Mod`.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Unexpected `PolynomialError` when using simple `subs()`" | The reported substitution must not raise `PolynomialError`. | Encoded in PO-001 and K claim `MOD-GCD-POLYERR`. |
| E2 | prompt | "`(Piecewise((x, y > x), (y, True)) / z) % 1` ... `PolynomialError`; That should be fixed." | Constructing modulo with a `Piecewise` dividend in this path must produce a symbolic result or other normal `Mod` behavior, not a leaked polynomial exception. | Encoded in PO-001 and PO-005. |
| E3 | prompt hint | "`gcd` will lead to `PolynomialError`. That error should be caught..." | `PolynomialError` from the optional `gcd` simplification is not part of the `Mod` API contract for this symbolic input class. | Encoded in PO-001. |
| E4 | `Mod` docstring | "`x**2 % y` -> `Mod(x**2, y)`" | Symbolic modulo construction is allowed to remain unevaluated when it cannot compute a concrete remainder. | Encoded in PO-001 fallback result. |
| E5 | code comment | "extract gcd; any further simplification should be done by the user" | The `gcd` step is a simplification attempt, not a required semantic error boundary. | Encoded in PO-001 and PO-002. |
| E6 | traceback | `sympy/core/mod.py`, `G = gcd(p, q)` raises `PolynomialError`. | The repaired edge must be localized to this call and its immediate simplification use. | Encoded in PO-004 and PO-005. |
| E7 | `Mod.eval` code | `if q.is_zero: raise ZeroDivisionError("Modulo by zero")` before the `gcd` block. | The repair must not swallow legitimate modulo-by-zero behavior. | Encoded in PO-003. |
| E8 | prompt discussion | Branchwise `gcd(Piecewise(...), x)` is a possible future behavior, but "gets messier" for two `Piecewise` expressions. | Do not define new branchwise polynomial `gcd` semantics as part of this targeted `Mod` repair. | Recorded as F-003, not a code-change obligation. |
| E9 | prompt discussion | Old assumptions can cache `None` after an exception, but removing that line causes many other recursion examples. | Do not use assumptions-cache rewrites as the primary repair; they do not by themselves satisfy the no-`PolynomialError` intent. | Recorded as F-004, not a code-change obligation. |

## Contract

For `Mod.eval(p, q)` after earlier direct-evaluation, denesting, `Add`, and
`Mul` preparation have not returned a result:

1. If `q.is_zero` is true, `Mod.eval` raises `ZeroDivisionError` as before.
2. If `gcd(p, q)` succeeds, `Mod.eval` preserves the existing common-factor
   simplification behavior: when `G != 1`, it simplifies `p/G` and `q/G` with
   `gcd_terms`; otherwise it continues with `G = 1`.
3. If `gcd(p, q)` or the immediately associated `gcd_terms` extraction raises
   `PolynomialError`, `Mod.eval` treats the common factor as `S.One`, leaves
   `p` and `q` unchanged, and continues constructing/simplifying the symbolic
   modulo expression. The `PolynomialError` must not escape this optional block.
4. The catch is limited to `PolynomialError` from the optional extraction block.
   It must not change earlier numeric evaluation, `_eval_Mod`, ratio/difference
   simplifications, or the modulo-by-zero error.

## Domain and Frame Conditions

The no-`PolynomialError` obligation applies to symbolic SymPy expressions in the
`Mod` construction path where the denominator is not known to be zero and the
only failing operation is polynomial conversion for common-factor extraction.
The specification intentionally does not define branchwise `gcd` for `Piecewise`
or the global old-assumptions cache rollback policy.

Frame conditions:

- Public callable shape is unchanged: `Mod(p, q)` and `Mod.eval(cls, p, q)` keep
  the same arguments and return protocol.
- Existing successful `gcd` simplifications are preserved.
- Existing non-polynomial exceptions outside the scoped `gcd` extraction block
  are not caught by this repair.

## Discriminator

The model distinguishes the defect from the fixed behavior:

- Failing pre-fix class: a `Piecewise`-containing dividend reaches the optional
  `gcd` extraction and `gcd` raises `PolynomialError`, which escapes.
- Passing fixed class: the same symbolic inputs take the `PolynomialError`
  fallback edge, set `G = 1`, preserve `p` and `q`, and continue to symbolic
  `Mod` construction.
- Unchanged supported class: inputs whose polynomial `gcd` succeeds still use
  the existing `G != 1` simplification path.

