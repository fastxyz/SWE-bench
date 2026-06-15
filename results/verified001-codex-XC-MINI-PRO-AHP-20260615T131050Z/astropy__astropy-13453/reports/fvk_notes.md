# FVK Notes

## Decision Summary

The FVK audit confirms V1 stands unchanged. I made no additional source edits in
the FVK pass.

## Trace To Findings

- `fvk/FINDINGS.md` F1 identifies the original bug: HTML output ignored
  supplied `formats`. V1 resolves it by setting `self.data.cols` and calling
  `self.data._set_col_formats()` before creating any `iter_str_vals()`
  iterator.
- `fvk/FINDINGS.md` F2 identifies the completeness risk for multidimensional
  HTML output: temporary split columns could otherwise bypass the source
  column's active format. V1 resolves it by assigning
  `new_col.info.format = col.info.format` before rendering split-column values.
- `fvk/FINDINGS.md` F3 is a proof honesty boundary, not a source-code defect:
  the proof is constructed over a focused mini-semantics and was not
  machine-checked. It does not justify another code edit; it just requires
  keeping the caveat and not removing tests.

## Trace To Proof Obligations

- O1 and O2 justify keeping the V1 one-dimensional path: the added
  `self.data.cols = cols` gives `_set_col_formats()` the same column context as
  other ASCII writers, and the existing HTML call to
  `col.info.iter_str_vals()` then observes the supplied format.
- O3 justifies no extra handling for columns absent from `formats`: the shared
  `_set_col_formats()` helper already preserves those columns.
- O4 justifies not changing fill-value or raw-HTML code: V1 leaves the
  downstream `fill_values(...)` wrapper and escape/bleach branch unchanged.
- O5 justifies retaining the V1 multicolumn line
  `new_col.info.format = col.info.format`; it discharges the split-column
  propagation obligation surfaced in F2.
- O6 confirms no public compatibility edit is required because V1 changes no
  public signature, registry name, return shape, or callsite protocol.
- O7 explains why no test removal or machine-checked claim is made in this
  benchmark session.

## Code Changes In This Phase

None. The only files added in this phase are FVK artifacts under `fvk/` and this
report. The production source remains the V1 fix in
`repo/astropy/io/ascii/html.py`.
