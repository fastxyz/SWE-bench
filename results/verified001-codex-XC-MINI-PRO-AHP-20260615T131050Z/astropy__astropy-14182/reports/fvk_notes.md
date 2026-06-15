# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision Summary

V1 stands unchanged. The FVK audit found that the existing V1 edit satisfies the
public issue contract for nonempty RST `header_rows`, including the concrete
`["name", "unit"]` case, and does not introduce a public compatibility problem.

## Trace From Findings to Decisions

- F-001 identified the original reported bug: `ascii.rst` rejected
  `header_rows` with a constructor `TypeError`. O1 discharges this because
  `RST.__init__` now accepts `header_rows` and forwards it to the fixed-width
  base class. Decision: keep the V1 constructor change.
- F-002 identified the separator-placement requirement for more than one header
  row. O3 discharges this by proving the separator index is
  `len(self.header.header_rows)`, and O4 shows the default one-header case still
  selects the previous `lines[1]`. Decision: keep the V1 `RST.write` change.
- F-003 identified a readback line-index risk for generated multi-header RST
  tables. O5 discharges this because V1 sets `self.data.start_line` to
  `len(self.header.header_rows) + 2`. Decision: keep this V1 constructor detail
  even though the issue title emphasizes output, because it follows the
  fixed-width header-row behavior used as public evidence.
- F-004 records `header_rows=[]` as underspecified rather than a required repair.
  O7 defines the verified domain as nonempty header rows, matching the public
  issue example and "header rows" wording. Decision: do not expand the patch to
  no-header RST behavior in this iteration.
- F-005 records empty-table behavior as inherited and out of scope. O7 excludes
  it because the public issue reports a constructor failure on a table with data
  rows. Decision: do not alter shared fixed-width width calculation.

## Compatibility Decision

O6 found no in-repo `RST` subclass or override that would be broken by adding an
optional constructor keyword. Existing zero-argument construction still follows
O4. Decision: no compatibility patch is needed.

## Artifact Decisions

The required FVK artifacts were written under `fvk/`:

- `SPEC.md` records the intent specification, public evidence ledger, abstract
  model, and K-style claims.
- `FINDINGS.md` records the closed findings, residual boundaries, and no-open-bug
  conclusion.
- `PROOF_OBLIGATIONS.md` traces each obligation to evidence and findings.
- `PROOF.md` provides the constructed proof and the K commands that were not
  executed.
- `ITERATION_GUIDANCE.md` states why V1 stands and what should not be changed in
  this iteration.

No test files were modified, and no additional source files were changed during
the FVK phase.

