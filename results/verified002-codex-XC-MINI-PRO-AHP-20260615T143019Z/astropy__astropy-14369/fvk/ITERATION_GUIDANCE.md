# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change in `repo/astropy/units/format/cds.py`.

Reason: the audit found the original bug mechanism (F-001), verified that V1's
`division_tail` semantic value discharges the chained-division obligations
(PO-1, PO-2), and checked that V1 does not over-flatten parentheses (F-002,
PO-3) or require a generated parser-table update (F-003, PO-6).

## Next Code Changes

No production-code change is recommended in this FVK iteration.

Do not modify test files in this benchmark. In normal project work, add tests
for the issue examples and a parenthesized grouping case.

## Commands To Run Later

FVK machine check, in an environment with K installed:

```sh
kompile fvk/mini-cds-units.k --backend haskell
kast --backend haskell fvk/cds-parser-spec.k
kprove fvk/cds-parser-spec.k
```

Astropy validation, in an environment where running tests is allowed:

```sh
python -m pytest astropy/units/tests/test_format.py -k cds
python -m pytest astropy/io/ascii/tests -k cds
```

These commands were not run in this benchmark session.

## Suggested Tests For Future Work

- Parse `10+3J/m/s/kpc2` with `format="cds"` and assert equivalence to
  `1000 J / (m s kpc2)`.
- Parse `10-7J/s/kpc2` with `format="cds"` and assert equivalence to
  `1e-7 J / (s kpc2)`.
- Read the issue's MRT snippet through `Table.read(..., format="ascii.cds")`
  and assert the column units.
- Parse `J/(m/s)` and assert the grouped denominator remains `m/s`.
- Keep existing CDS grammar coverage for scale factors, dimensionless units,
  `km/s`, and `[cm/s2]`.

## Residual Risk

The proof is constructed, not machine-checked. The mini-CDS K semantics is a
purpose-built model of the parser actions, not the full Python or Astropy
runtime. The residual risk is therefore in model adequacy and in unexecuted
integration behavior, not in an identified source-code defect.
