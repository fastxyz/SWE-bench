# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK artifacts justify the original source fix and do
not justify any broader source edit.

## Decisions Traced to Findings and Obligations

- Kept the `TooManyRedirects` import and catch-tuple change in
  `repo/sphinx/builders/linkcheck.py`: Finding F-001 identifies the pre-V1 bug,
  Finding F-002 confirms V1 routes that case into GET, and PO-04 is discharged
  by the inner fallback handler.
- Made no additional production source changes during this iteration: F-002 and
  PO-04 show the named issue path is already fixed by V1.
- Did not broaden the fallback to all Requests exceptions: Finding F-003 and
  PO-06 reject that alternative because the public intent names
  `TooManyRedirects`, while unrelated connection/SSL/timeouts lack fallback
  evidence.
- Did not alter anchor handling: PO-01 scopes this proof to the non-anchor
  HEAD-then-GET branch, and the intent spec records that anchor checks already
  use GET to inspect content.
- Did not alter behavior when fallback GET itself raises `TooManyRedirects`:
  Finding F-004 and PO-05 classify that as broken because GET also failed.
- Did not change public APIs, output schemas, config values, or tests: PO-08 and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no compatibility issue.

## Artifact Notes

The FVK package includes the five requested artifacts plus the adequacy and K
core files required by the FVK docs. The K proof is constructed, not
machine-checked; commands are recorded in `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md` but were not executed, per the task constraints.
