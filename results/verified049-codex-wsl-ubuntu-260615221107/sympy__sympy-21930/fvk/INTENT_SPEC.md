# Intent Spec

Status: intent-only, derived from the public issue text and public in-repo tests.

I1. Powered bosonic creation operators must not render with an ungrouped LaTeX
double superscript. If the direct creator base is `b^\dagger_{i}` and the
exponent is `e`, the powered form must be `{b^\dagger_{i}}^{e}`.

I2. The same obligation applies to fermionic creation operators because they use
the same daggered superscript structure: direct base `a^\dagger_{i}` powered by
`e` must render as `{a^\dagger_{i}}^{e}`.

I3. Direct, unpowered creation-operator output must remain unchanged:
`b^\dagger_{i}` for `Bd(i)` and `a^\dagger_{p}` for `Fd(p)`.

I4. Non-creator LaTeX power behavior must remain unchanged except where the
secondquant creator grouping obligation applies.

I5. The fix must not change public constructors, aliases, direct `_latex`
signatures, or public caller contracts.

