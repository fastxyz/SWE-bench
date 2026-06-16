# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Root cause confirmed

Input class: multivariate polynomial over an algebraic extension with a factor
that depends only on lower variables, e.g. `(x - 1)*(y - 1)` over `QQ(I)`.

Observed pre-V1 behavior from the public issue: `factor(z, extension=[I])`
returned `x - 1`.

Expected behavior from public intent: the result must preserve both factors, so
the product is `(x - 1)*(y - 1)` up to coefficient/order.

Cause: the old `dmp_ext_factor` applied `dmp_sqf_part` to the whole monic
polynomial before computing the square-free norm. Since `dmp_sqf_part`
differentiates with respect to the leading variable, lower-variable content
such as `y - 1` is divided out by the GCD with the derivative and never reaches
the norm/trial-division stage.

Classification: code bug fixed by V1.

Related obligations: PO2, PO3, PO4, PO8.

## F2: V1 preserves lower-variable content

Input class: `F = G * P`, where `G` is content in lower variables and `P` is
primitive with respect to the leading variable.

V1 behavior: `dmp_ext_factor` now calls `dmp_primitive(F, u, K)`, factors `G`
recursively at level `u - 1`, lifts each lower-level factor with `[g]`, and
keeps those factors in the final factor list.

Expected behavior: all factors of `G` remain present in the final
factorization.

Classification: positive finding; V1 discharges the issue's missing-factor
obligation.

Related obligations: PO3, PO4, PO5, PO8.

## F3: Primitive factor path remains covered

Input class: primitive part `P` with positive leading-variable degree.

V1 behavior: the previous square-free norm reconstruction is still used for
`P`, and multiplicities are recovered by trial division against the original
monic polynomial `F`.

Expected behavior: V1 should not regress factors involving the leading variable
or their multiplicities.

Classification: positive finding, conditional on existing helper contracts for
`dmp_sqf_norm`, `dmp_factor_list_include`, `dmp_inner_gcd`,
`dmp_compose`, and `dmp_trial_division`.

Related obligations: PO6, PO7, PO8.

## F4: No public compatibility problem found

Changed public API: none.

Observed V1 change: body-only modification in `dmp_ext_factor`; no signature,
return type, dispatch, or test file changes.

Expected behavior: existing callers keep receiving `(coefficient, factors)`.

Classification: compatibility pass.

Related obligations: PO11.

## F5: Proof capability boundary

The constructed proof does not reverify all of SymPy's dense-polynomial algebra
or algebraic-number-field factorization. It relies on existing helper contracts:
`dmp_primitive` returns content and primitive part whose product is the input;
`dmp_factor_list` returns a complete factorization of its input;
`dmp_trial_division` recovers multiplicities for candidate factors; and the
existing square-free norm path reconstructs primitive factors.

Classification: proof capability gap, not a newly found code bug. Machine
checking would require either a much larger K model of dense polynomial algebra
or trusted/previously proved helper lemmas.

Related obligations: PO1, PO6, PO7, PO10.

## F6: Recommended public regression tests, not applied

Suggested tests after this coding task, if test edits were allowed:

- `factor(expand((x - 1)*(y - 1)), extension=[I])` preserves both factors.
- A content-only multivariate input with explicit generators, such as
  factoring `y**2 + 1` over `extension=[I]`, preserves lower-variable factors.
- A repeated-content case, such as `(x - 1)**2*(y - 1)**3`, preserves
  multiplicities.

Classification: test gap only. Test files were not modified because the task
forbids it.

Related obligations: PO4, PO7, PO8.

