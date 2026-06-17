# Intent Spec

Status: constructed from public evidence; no test, Python, or K command was run.

## I-1: `PolyElement.as_expr` accepts replacement symbols

Public intent says `PolyElement.as_expr()` is "supposed to let you set the
symbols you want to use." Therefore, for a polynomial with `ngens` generators,
calling `as_expr(*symbols)` with exactly `ngens` supplied symbols must build the
expression with those supplied symbols, not with `self.ring.symbols`.

## I-2: Default conversion remains unchanged

When no symbols are supplied, the existing and intended default is conversion
with `self.ring.symbols`.

## I-3: Wrong arity remains an error

The issue states that passing the wrong number of symbols produces an error. The
intent does not require changing the error type or message, only preserving the
wrong-arity rejection.

## I-4: Expression construction order is positional

The supplied symbols are positional replacements for the ring generators. The
first supplied symbol corresponds to the first monomial exponent, the second to
the second exponent, and so on.

## I-5: Public API shape is preserved

The public method signature is `as_expr(self, *symbols)`. The fix must not
require callers to switch to a different calling convention.

## I-6: Fraction-field forwarding remains compatible

`FracElement.as_expr(*symbols)` forwards its symbols to numerator and
denominator `PolyElement.as_expr`. The corrected `PolyElement` behavior should
therefore also make fraction-field conversion honor supplied symbols.
