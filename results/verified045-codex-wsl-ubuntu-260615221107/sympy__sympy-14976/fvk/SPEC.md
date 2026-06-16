# FVK Spec: mpmath Rational Printing

Status: constructed, not machine-checked.

## Target

The audited production change is `repo/sympy/printing/pycode.py`, specifically `MpmathPrinter._print_Rational`.

The observable behavior under audit is generated Python source from:

```python
lambdify(args, expr, modules='mpmath')
```

when `expr` contains non-integer SymPy rational constants.

## Public Intent Ledger

The ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- `E1`: the issue says mpmath lambdify "doesn't wrap rationals"; therefore non-integer rationals must be wrapped.
- `E2`: the symptom source contains `232/3`; this pre-fix display is SUSPECT legacy behavior and must not be preserved.
- `E3`: the precision failure arises because `232/3` is not evaluated at full mpmath precision; generated source must force mpmath arithmetic for that rational.
- `E4`: `lambdify` selects `MpmathPrinter` when `mpmath` is present.
- `E5`: the mpmath lambdify namespace provides `mpf`.

## Contract

For any normalized SymPy rational value with numerator `p` and denominator `q > 0`:

1. If `q == 1`, `MpmathPrinter._print_Rational` returns the decimal integer string for `p`.
2. If `q > 1` and `p >= 0`, it returns:

   ```text
   F(p)/F(q)
   ```

   where `F` is `_module_format('mpmath.mpf')`.

3. If `q > 1` and `p < 0`, it returns:

   ```text
   -F(abs(p))/F(q)
   ```

4. For the `lambdify(..., modules='mpmath')` default printer settings, `F` is `mpf`, and `mpf` is available in the generated function namespace.
5. Other printer backends remain unchanged.

## Precision-Relevant Property

For every non-integer rational, the generated division is not a division of two Python integer literals. Both operands are calls to mpmath's `mpf`, so Python dispatches the `/` operation through mpmath numeric values under the active mpmath precision.

## Scope and Limits

This proof models the expression string shape and the dispatch/namespace facts needed for the reported precision bug. It does not machine-check real Python parsing, real mpmath rounding internals, or the full SymPy printer hierarchy. Those are recorded as residual proof limitations in `FINDINGS.md` and `PROOF.md`, not as source bugs.
