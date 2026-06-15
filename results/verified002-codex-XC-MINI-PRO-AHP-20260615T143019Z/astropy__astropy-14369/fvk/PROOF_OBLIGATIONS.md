# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Semantic value invariant

For every parsed `unit_expression` or `combined_units`, the parser action returns
a semantic value with:

- `unit`: the actual standalone unit for that parsed expression.
- `division_tail`: the product to use when that expression occurs to the right
  of a slash in the right-recursive grammar.

Discharge argument: `_CDSUnit` stores exactly these two fields. Atomic units use
the same unit for both fields.

Linked findings: F-001.

## PO-2: Chained division keeps all repeated slash terms in the denominator

For a reduction of `unit_expression DIVISION combined_units`, if the left
expression has actual unit `A` and the right combined expression has flattened
tail `T`, the resulting actual unit is `A / T`.

Concrete required instances:

- `10+3J/m/s/kpc2 -> 1000 J / (m s kpc2)`
- `10-7J/s/kpc2 -> 1e-7 J / (s kpc2)`

Discharge argument: V1 computes
`_CDSUnit(p[1].unit / p[3].division_tail, ...)` for the division production.

Linked findings: F-001.

## PO-3: Parentheses reset the division tail

For `OPEN_PAREN combined_units CLOSE_PAREN`, the surrounding parser must treat
the grouped result as atomic. Its `division_tail` must be its actual grouped
unit, not the flattened product of its internal slash tree.

Concrete required instance:

- `J/(m/s) -> J / (m / s)`, not `J / (m s)`.

Discharge argument: V1 computes `_CDSUnit(p[2].unit)` for parenthesized
`unit_expression`, which sets `division_tail` to the same actual grouped unit.

Linked findings: F-002.

## PO-4: Product reductions preserve existing multiplication behavior

For `unit_expression PRODUCT combined_units`, the resulting actual unit is the
product of actual units, and the resulting tail is the product of tails.

Discharge argument: V1 computes
`_CDSUnit(p[1].unit * p[3].unit, p[1].division_tail * p[3].division_tail)`.
This preserves top-level products and correctly includes products that appear in
a denominator tail.

Linked findings: F-004.

## PO-5: Main, scale, and dex reductions unwrap actual units only

The final parser result must expose the actual unit, not the tail helper:

- `factor combined_units -> Unit(factor * combined.unit)`
- `combined_units -> Unit(combined.unit)`
- `[combined_units] -> dex(combined.unit)`
- `[DIMENSIONLESS]` and scale-only factors remain unchanged.

Discharge argument: V1 updates `p_main` to unwrap `_CDSUnit.unit` for combined
unit branches and keeps dimensionless/factor-only behavior on the old path.

Linked findings: F-004.

## PO-6: Shipped PLY parser table remains compatible

Because `cds_parsetab.py` is shipped and the task does not permit running the
regeneration commands, V1 must not require a parser-table update.

Discharge argument: V1 leaves all production docstrings, production function
names, arities, tokens, and lexer rules unchanged. Only semantic action bodies
changed, so the existing optimized table still binds the same reductions to the
same functions.

Linked findings: F-003.

## PO-7: No public API or caller compatibility regression

The repair must not change public signatures or the way `ascii.cds` calls unit
parsing.

Discharge argument: V1 adds only private `_CDSUnit` and changes internal parser
actions. `CDS.parse` and callers such as `Unit(unit, format="cds",
parse_strict="warn")` are unchanged.

Linked findings: F-004.
