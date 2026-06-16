# FVK Notes

## Decision summary

V1 stands unchanged. The FVK artifacts justify the existing-project branch as an
immediate status-1 exit and classify the old replacement-root prompt as SUSPECT
legacy behavior rather than a public requirement.

## Trace to findings and obligations

- No additional source edit was made because F1 shows the original empty-input
  bug is closed, and PO2/PO5 prove the audited branch exits with status 1 before
  generation.
- I kept the V1 choice to remove the replacement-root retry prompt because F2
  traces that prompt to the reported failure surface, while PO1/PO4 trace the
  accepted behavior to the public hint: an already-selected root with `conf.py`
  exits immediately with status 1.
- I kept the `source/conf.py` behavior covered by the same branch because F3 and
  PO3 trace it to the pre-existing quickstart guard and the separate-source
  layout.
- I did not change public signatures or call shapes because PO7 and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no compatibility blocker.
- I did not add or modify tests because the task forbids test edits. F4 records
  the recommended test cases for a later normal development pass.

## Verification limits

The proof in `fvk/PROOF.md` is constructed, not machine-checked. I did not run
tests, Python, `kompile`, `kast`, or `kprove`, per the benchmark constraints.
