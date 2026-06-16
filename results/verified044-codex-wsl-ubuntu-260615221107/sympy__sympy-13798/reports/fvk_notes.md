# FVK Notes

## Decision Summary

I left V1 source code unchanged. The FVK audit confirmed that the code now meets
the intent-derived obligations for custom `mul_symbol` strings while preserving
legacy aliases and default numeric separator behavior.

## Decision Trace

F-01 identified the pre-V1 bug: unknown `mul_symbol` values were rejected by a
fixed dictionary lookup. PO-02 is the corresponding obligation, and V1 satisfies
it by using any non-legacy string directly as `mul_symbol_latex`.

F-02 required backward compatibility for `None`, `"ldot"`, `"dot"`, and
`"times"`. PO-01 and PO-03 cover those behaviors. V1 preserves the legacy table
entries and keeps the `None` numeric separator special case.

F-03 addressed the only meaningful interpretation question: whether custom
separators should be padded automatically. PO-02 and PO-04 use the public hint
that an unknown argument is used as the LaTeX, so V1's literal separator behavior
stands. Callers who want padding can pass it in the custom string.

F-04 required scientific notation to keep a visible default separator. PO-03 and
PO-05 cover this; V1 leaves `mul_symbol=None` mapped to `r" \cdot "` for numeric
printing.

F-05 checked public compatibility. PO-07 covers this; V1 does not change public
function signatures or setting names.

F-06 records the benchmark honesty constraint. PO-08 covers it; I did not run
tests, Python, or K tooling, and the proof is labeled constructed, not
machine-checked.

## Source Changes In This Phase

No source files under `repo/` were changed during the FVK phase. The only new
files are the FVK artifacts under `fvk/` and this report.
