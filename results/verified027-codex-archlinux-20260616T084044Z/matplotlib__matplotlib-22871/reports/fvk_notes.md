# FVK Notes

## Decision summary

The FVK audit confirms the V1 source fix in
`repo/lib/matplotlib/dates.py`. No additional source edits were made during
the FVK pass.

## Decisions traced to findings and proof obligations

1. Keep the V1 no-January month-level offset rule.

   Trace: `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-001.

   Reason: V1 changes the only branch that caused the reported defect. For
   level `1`, `show_offset=True`, and no visible January tick, V1 leaves
   `show_offset` enabled so the existing offset-rendering branch uses
   `offset_formats[1]`, which is `%Y` by default.

2. Do not change the January-visible month-level behavior.

   Trace: F-002 and PO-002.

   Reason: public docs and existing public tests support the concise behavior
   where January ticks carry the year through `zero_formats[1]`, making the
   offset redundant.

3. Do not alter levels finer than months or TeX wrapping.

   Trace: F-003, PO-004, PO-006, and PO-007.

   Reason: the issue concerns month-level offset suppression. The V1 diff is
   framed so day/hour/minute/second offsets, label formatting, second trimming,
   and `_usetex` wrapping stay on their existing paths.

4. Preserve `show_offset=False` semantics.

   Trace: F-004 and PO-005.

   Reason: the local `show_offset` variable still starts from the public
   setting and V1 only ever changes it from true to false.

5. Do not add an empty-input repair in this pass.

   Trace: F-005 and PO-008.

   Reason: empty `values` is a separate robustness question not evidenced by
   the public issue. Adding that behavior here would broaden the patch beyond
   the no-January offset bug.

6. Treat the FVK proof as constructed, not machine-checked.

   Trace: F-006 and PO-008.

   Reason: this session forbids executing tests, Python, `kompile`, or
   `kprove`. The artifacts include the commands for a later machine-checking
   environment, but no test removal or stronger verification claim is made.

## Artifacts written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-date.k`
- `fvk/concise-date-formatter-spec.k`
- adequacy and compatibility notes under `fvk/`

