# Formal Spec English

C1. Standard power claim: if a secondquant creation operator directly prints as
`L`, then raising it to an exponent that prints as `E` produces `{L}^{E}`.

C2. Folded fractional-power claim: if a secondquant creation operator directly
prints as `L`, then folded rational exponent `P/Q` produces `{L}^{P/Q}`.

C3. Direct creator frame claim: directly printing a secondquant creation
operator still produces `L`, without adding outer braces.

C4. Non-hook frame claim: if a power base does not provide `_latex_power_base`,
the LaTeX power printer follows the same branch-specific behavior as before this
fix.

C5. Compatibility claim: the fix adds only an optional private hook and does not
change public constructors, aliases, existing method signatures, or direct
operator output shape.

