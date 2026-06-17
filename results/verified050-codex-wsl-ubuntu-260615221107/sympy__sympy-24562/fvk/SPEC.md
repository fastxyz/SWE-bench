# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Target

`repo/sympy/core/numbers.py`, `Rational.__new__`, specifically the two-argument normalization path after the optional one-argument parsing branch.

## Intent Summary

The intended behavior is that valid rational-like two-argument inputs are first converted to rational values and then divided. If `Rational(p) = PN/PD` and `Rational(q) = QN/QD`, with positive denominators, the finite quotient represented by `Rational(p, q)` is:

```text
(PN * QD) / (PD * QN)
```

The reported failure `Rational('0.5', '100') -> 1/100100` violates this because it uses raw Python string repetition on the unconverted denominator. The intended result is `1/200`.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. Critical entries:

- E1: The issue names `1/100100` as wrong and `1/200` as correct for `Rational('0.5', '100')`.
- E2: The public hint says `Rational('0.5') / Rational('100')` yields the expected `1/200`.
- E3: The public hint proposes an integer denominator accumulator.
- E4: The public suggested test makes this a family property over valid rational-like operands.
- E5/E6: Existing docs and tests require broad accepted inputs, invalid-input errors, zero-denominator behavior, and `gcd=1` behavior to remain compatible.

## Formal Domain

This FVK pass models the normalization block over converted rational pairs:

```text
Rational(p) = PN/PD, PD > 0
Rational(q) = QN/QD, QD > 0
```

For finite quotient obligations, `QN != 0`. The `QN == 0` branch is specified separately as existing SymPy zero-denominator behavior.

## Formal Claims

The K-style artifacts are:

- `fvk/mini-rational.k`: a minimal semantics for the rational normalization state.
- `fvk/rational-normalization-spec.k`: claims for the quotient property, the reported concrete case, and zero-denominator frame behavior.

The key claim is `RATIONAL-QUOTIENT`: normalization reaches `canonical(PN * QD, PD * QN, autoGcd, false)`.

## Adequacy

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent-only obligations in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks all clauses as pass. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API or override compatibility issue.

## Frame Conditions

The patch must not change:

- one-argument parsing;
- invalid input errors for non-rational inputs;
- zero-denominator handling;
- negative denominator sign normalization;
- gcd reduction and `gcd=1`;
- canonical singleton returns such as `Integer` and `S.Half`.

The source diff only changes how the pre-canonical numerator and denominator are computed, so these branches remain downstream and unchanged.
