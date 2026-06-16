# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Decimal input is in domain

Evidence: issue text and public tests use `Decimal` values with `floatformat`.

Obligation: the spec must quantify over existing `Decimal` inputs rather than
excluding them as unsupported.

Status: discharged by C-DECIMAL-PRESERVE and the V1 branch
`isinstance(text, Decimal)`.

## PO-2: Decimal conversion preserves the exact value

Evidence: issue text identifies conversion through `float` as the root cause.

Obligation: for Decimal input `D`, the value passed to rounding/rendering is
exactly `D`.

Status: discharged by V1 code:

```python
if isinstance(text, Decimal):
    input_val = str(text)
    d = text
```

and by K claim `DECIMAL-PRESERVE`.

## PO-3: The concrete issue point renders exactly

Evidence: `Decimal('42.12345678901234567890')` with `floatformat:20` currently
prints `42.12345678901234400000`, which the issue reports as precision loss.

Obligation: with exact Decimal conversion, existing ROUND_HALF_UP quantization
to 20 places renders `42.12345678901234567890`.

Status: discharged by claim `ISSUE-DECIMAL-20`, relying on the external Decimal
rendering fact encoded in `mini-floatformat.k`. Constructed, not
machine-checked.

## PO-4: Frame non-Decimal and suffix behavior

Evidence: docs and public tests cover floats, numeric strings, invalid suffixes,
grouping, localization, infinity/NaN, and low-context Decimal rounding.

Obligation: the Decimal precision fix must not alter non-Decimal conversion or
suffix/localization parsing.

Status: discharged by source diff inspection: only the Decimal conversion branch
changed; the non-Decimal branch still uses `repr(text)` and the same fallback.
Encoded by K claim `NONDECIMAL-FRAME`.

## PO-5: Public API compatibility

Evidence: `floatformat` is a registered public template filter.

Obligation: keep signature, decorator, and return protocol compatible.

Status: discharged by source diff inspection and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-6: Honesty boundary

Evidence: task forbids tests, Python execution, and K tooling.

Obligation: artifacts must state that proofs are constructed, not
machine-checked, and must not recommend deleting tests as an executed result.

Status: discharged in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
