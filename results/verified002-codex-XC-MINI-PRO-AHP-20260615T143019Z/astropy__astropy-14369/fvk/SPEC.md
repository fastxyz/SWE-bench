# FVK Specification: CDS Composite Unit Parsing

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target under audit: `repo/astropy/units/format/cds.py`, specifically the parser
semantic actions inside `CDS._make_parser`.

Out of scope for this repair: lexer tokenization, the CDS unit registry, table
I/O column parsing outside its call to `Unit(unit, format="cds")`, and unit
string formatting.

## Intent Spec

1. CDS/MRT unit strings are written without spaces and may use repeated `/`
   separators for composite physical units.
2. A unit written as `10+3J/m/s/kpc2` denotes `1000 J / (m s kpc2)`, matching
   the issue's physical source unit `erg/AA/s/kpc^2`.
3. A unit written as `10-7J/s/kpc2` denotes `1e-7 J / (s kpc2)`.
4. Existing CDS grammar behavior remains in force for one-slash units, scaled
   factors, powers such as `s2`, bracketed logarithmic units, and dimensionless
   units.
5. Parentheses remain explicit grouping. If an expression is written inside
   parentheses, the grouped expression is atomic to the surrounding division.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "units should be SI without spaces" | Reject spaces and preserve CDS compact grammar. | Encoded by existing parser; unchanged. |
| E2 | prompt | "`erg/AA/s/kpc^2` ... should be written as `10+3J/m/s/kpc2`" | Repeated slash-separated terms after `J` are denominator factors. | Encoded by claims C1/C2. |
| E3 | prompt | "For the SBCONT column the second is in the wrong place" | `s` must not move into the numerator for `J/m/s/kpc2`. | Resolved by V1 `division_tail`. |
| E4 | prompt | "for SBLINE kpc2 is in the wrong place" | `kpc2` must not move into the numerator for `J/s/kpc2`. | Resolved by V1 `division_tail`. |
| E5 | prompt hint | Generic `u.Unit('10+3J/m/s/kpc2')` prints `1000 J / (kpc2 m s)` | Generic parser is supporting public evidence for grouping all repeated slash terms as denominator factors. | Encoded by expected claim results. |
| E6 | public tests | CDS tests cover `km/s`, `mW/m2`, `[cm/s2]`, scale-only units, and dimensionless units. | Existing grammar surface and ordinary one-slash parsing must be preserved. | Encoded by frame obligations. |
| E7 | code comments | Generated PLY parser table is shipped and regenerated only by a build/test flow. | A semantic-only fix should not require a parser-table change unless grammar productions change. | Encoded by compatibility obligation. |

## Formal Model

The formal core is in:

- `fvk/mini-cds-units.k`
- `fvk/cds-parser-spec.k`

The mini semantics models the parser reductions with a semantic value:

`sem(actual, tail)`

`actual` is the unit if the parsed expression is used as a complete value.
`tail` is the product of terms that must be used when the expression appears to
the right of a slash.

The key equations are:

- `unit(U) -> sem(U, U)`
- `paren(C) -> sem(actual(C), actual(C))`
- `prod(E, C) -> sem(actual(E) * actual(C), tail(E) * tail(C))`
- `div(E, C) -> sem(actual(E) / tail(C), tail(E) * tail(C))`
- `scaled(S, C) -> S * actual(C)`
- `dexed(C) -> dex(actual(C))`

These equations correspond to V1's `_CDSUnit.unit` and
`_CDSUnit.division_tail`.

## Formal Spec English

Claim C1: parsing `10+3J/m/s/kpc2` reaches the unit
`p1000 * (J / (m * s * kpc2))`.

Claim C2: parsing `10-7J/s/kpc2` reaches the unit
`p1em7 * (J / (s * kpc2))`.

Claim C3: parsing `J/(m/s)` reaches `J / (m / s)` because parentheses reset the
division tail to the grouped expression's actual unit.

Claim C4: parsing `km/s` still reaches `km / s`, so ordinary one-slash CDS
division is preserved.

## Adequacy Audit

| Claim | Intent coverage | Verdict |
| --- | --- | --- |
| C1 | E2, E3, E5 | Pass. It states the issue's continuum unit exactly. |
| C2 | E4, E5 | Pass. It states the issue's line surface-brightness unit exactly. |
| C3 | E5 plus default grouping convention | Pass. It prevents the fix from over-flattening explicit grouping. |
| C4 | E6 | Pass. It confirms a core existing grammar case remains unchanged. |

No claim is derived solely from the V1 implementation. Implementation facts are
used only to model the candidate reduction steps being checked against the
intent.

## Public Compatibility Audit

Changed public symbols: none.

New symbol: `_CDSUnit`, a private module-local helper class.

Parser grammar signatures: unchanged. The PLY production docstrings, names, and
arities are unchanged, so the existing `cds_parsetab.py` automaton still matches
the source productions and binds to the same semantic action names.

Public callers: `astropy.io.ascii.cds` still calls `Unit(unit, format="cds",
parse_strict="warn")`; no call shape changed.

Compatibility verdict: pass.
