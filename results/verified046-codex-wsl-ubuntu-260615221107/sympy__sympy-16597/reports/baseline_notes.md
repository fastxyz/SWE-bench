# Baseline Notes

## Root cause

The old assumptions rule table in `sympy/core/assumptions.py` derives
`integer -> rational`, and derives parity from integers with
`even == integer & !odd` and `odd == integer & !even`. It also derives
`rational -> real` and `rational -> algebraic`, but it did not derive
`rational -> finite`.

As a result, `Symbol('i', integer=True)` and `Symbol('m', even=True)` could
deduce that they were rational/real/algebraic, but the closure had no path to
`finite=True`, so `.is_finite` remained `None`.

## Files changed

`repo/sympy/core/assumptions.py`

Added `rational -> finite` to `_assume_rules`. Since integers already imply
rational and even/odd already imply integer, this single rule makes rational
symbols, integer symbols, and parity-constrained symbols finite through the
existing deduction machinery. The existing `infinite -> !finite` rule supplies
the inverse consistency behavior through the fact engine's contrapositive
handling, so non-finite values cannot also be rational.

## Assumptions and alternatives

I assumed that the issue concerns the old `.is_*` assumption attributes used by
`Symbol(..., even=True).is_finite`, not only the newer `ask(Q.*)` API.

I considered adding `finite` directly to `integer`, `even`, or `odd`, but that
would only fix the reported examples while leaving rational symbols with the
same missing implication. I also considered changing `real` to imply `finite`,
but this codebase treats old-assumption `real` as broad enough to include
infinite real quantities in some paths, and the public hint called out that such
a change would be riskier. Adding the implication at `rational` is the minimal
rule that fixes the reported cases and the directly related rational/integer
classes without altering the meaning of `real`.
