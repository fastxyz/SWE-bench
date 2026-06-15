# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof obligations only.

## F-001: Right-recursive division moved denominator terms into the numerator

Classification: code bug, resolved by V1.

Evidence: the issue reports that `10+3J/m/s/kpc2` was parsed as
`1e+3 J s / (kpc2 m)` and that `10-7J/s/kpc2` was parsed as
`1e-7 J kpc2 / s`.

Observed pre-fix mechanism: the grammar production
`unit_expression DIVISION combined_units` is right-recursive. Without extra
semantic state, `J/m/s/kpc2` reduces as `J / (m / (s / kpc2))`.

Expected: `10+3J/m/s/kpc2 -> 1000 J / (m s kpc2)` and
`10-7J/s/kpc2 -> 1e-7 J / (s kpc2)`.

Resolution: V1 introduces `_CDSUnit.division_tail` and changes the division
action to divide by the right operand's flattened tail. See proof obligations
PO-1 and PO-2.

## F-002: The fix must not flatten explicit parentheses

Classification: regression risk, discharged by V1.

Evidence: the CDS parser grammar has `OPEN_PAREN combined_units CLOSE_PAREN`,
and ordinary grammar conventions make parentheses explicit grouping.

Risk: a broad "all slash terms are denominator terms" rule could accidentally
make `J/(m/s)` behave like `J/(m*s)`.

Resolution: V1 wraps a parenthesized `combined_units` as `_CDSUnit(p[2].unit)`,
so its `division_tail` is reset to its actual grouped unit. See PO-3.

## F-003: Parser-table compatibility is required

Classification: compatibility obligation, discharged by V1.

Evidence: `cds.py` comments describe generated `_lextab.py` and `_parsetab.py`
files, and the repository ships `cds_parsetab.py`.

Risk: changing grammar productions without regenerating the table would leave
the optimized PLY parser using stale automaton data.

Resolution: V1 changes only semantic action bodies. Production docstrings,
names, arities, and token definitions are unchanged, so `cds_parsetab.py`
remains compatible. See PO-6.

## F-004: No unresolved source-code finding surfaced by FVK

Classification: confirmation.

Evidence: PO-1 through PO-7 cover the issue examples, the general chained
division invariant, parentheses, ordinary one-slash parsing, main/factor/dex
unwrapping, parser-table compatibility, and public call compatibility.

Decision: keep V1 source unchanged.

## Residual Caveat

The proof is constructed, not machine-checked. The exact K commands are recorded
in `fvk/PROOF.md`, but they were not run because the task forbids K tooling and
there is no execution environment.
