# Formal Spec English

Status: constructed, not machine-checked.

## Claim C1: Positive Non-Integer Rational

For every normalized SymPy rational `p/q` with `q > 1` and `p >= 0`, `MpmathPrinter._print_Rational` must produce a Python expression equivalent in form to:

```text
<mpf-name>(p)/<mpf-name>(q)
```

where `<mpf-name>` is the printer's `_module_format('mpmath.mpf')` result, such as `mpf` for `lambdify(..., modules='mpmath')` or `mpmath.mpf` for fully-qualified code.

## Claim C2: Negative Non-Integer Rational

For every normalized SymPy rational `p/q` with `q > 1` and `p < 0`, `MpmathPrinter._print_Rational` must produce:

```text
-<mpf-name>(abs(p))/<mpf-name>(q)
```

This keeps the sign outside the wrapped magnitude while still ensuring the division operands are mpmath values.

## Claim C3: Integer-Valued Rational

For every rational printer input with `q == 1`, the output is the integer numerator string. There is no rational division to wrap and no precision-loss division literal.

## Claim C4: Lambdify Reachability

When `lambdify` is called without a custom printer and its module list contains `mpmath`, it selects `MpmathPrinter`, so claims C1-C3 apply to the generated function source.

## Claim C5: Namespace Adequacy

In the mpmath lambdify namespace, `mpf` is available because the namespace is populated with `from mpmath import *`; therefore the unqualified output from `_module_format(..., fully_qualified_modules=False)` is executable in the generated function's namespace.

## Claim C6: Frame Condition

The change does not alter rational printing for other printer classes because `_print_Rational` is added only to `MpmathPrinter`.

## Claim C7: Surrounding Expression Preservation

When the wrapped rational appears inside an addition, power exponent, or multiplication, the existing printer precedence and parenthesizing rules preserve the same mathematical grouping while replacing only the rational literal form.
