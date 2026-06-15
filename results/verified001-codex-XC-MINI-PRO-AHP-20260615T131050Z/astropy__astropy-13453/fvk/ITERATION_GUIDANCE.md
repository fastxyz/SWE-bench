# Iteration Guidance

Status: FVK feedback package for the next coding pass.

## Decision

V1 stands unchanged. The audit found that V1 discharges the relevant
format-propagation obligations:

- O1 and O2: one-dimensional HTML cells use `formats` through the existing
  Astropy `iter_str_vals()` path.
- O3 and O4: columns without supplied formats, fill values, and raw HTML
  behavior remain framed.
- O5: split multicolumn cells inherit the source column format.
- O6: public call signatures and return shape are unchanged.

## Recommended Follow-Up Tests

Do not edit tests in this benchmark. For a normal development pass, add or keep
tests covering:

1. `Table.write(..., format="html", formats={"a": callable})` on a
   one-dimensional column.
2. `format="ascii.html"` alias with a string format specifier.
3. A multidimensional column rendered with `htmldict={"multicol": True}` and a
   format entry for the source column.
4. A formatted column combined with `fill_values`.
5. A formatted raw HTML column to confirm formatting happens before the
   existing escape or bleach-cleaning branch.

## Machine Verification

Run the commands listed in `PROOF.md` in an environment with K installed before
claiming machine-checked proof or removing any tests as redundant.

## Open Questions

None for the reported issue. The full HTML writer has broader behavior not
modeled here, such as complete HTML serialization, file I/O, and parser support;
those remain test-covered integration behavior rather than proof-covered
format-propagation behavior.
