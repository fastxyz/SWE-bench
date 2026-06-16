# Public Evidence Ledger

E1. Source: prompt. Quote: "Issues with Latex printing output in second
quantization module". Obligation: audit secondquant LaTeX output.

E2. Source: prompt. Quote: `b^\dagger_{0}^{2}`. Obligation: identify the
ungrouped double-superscript shape as faulty.

E3. Source: prompt. Quote: "It should be correct by adding curly brackets
`{b^\dagger_{0}}^{2}`". Obligation: group the whole daggered base before the
outer exponent.

E4. Source: public tests. Quote: `assert latex(o) == "b^\\dagger_{i}"`.
Obligation: preserve direct `Bd(i)` output.

E5. Source: public tests. Quote: `assert latex(Fd(p)) == r'a^\dagger_{p}'`.
Obligation: preserve direct `Fd(p)` output.

E6. Source: public tests. Quote: `assert latex(x_star**2) ==
r"\left(x^{*}\right)^{2}"`. Obligation: preserve existing symbol superscript
protection.

E7. Source: implementation. Fact: `CreateBoson._latex` and
`CreateFermion._latex` both emit a daggered base with an internal superscript.
Obligation: the shared `Creator` base class is the right local place for a
power-base hook.

E8. Source: implementation. Fact: standard powers and folded fractional powers
both append an outer exponent to a printed base. Obligation: both branches must
honor the grouped creator base.

