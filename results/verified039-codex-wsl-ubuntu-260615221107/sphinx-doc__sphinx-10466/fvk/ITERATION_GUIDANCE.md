# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

- F1 confirms V1 satisfies the core duplicate-location intent.
- PO1-PO6 cover the needed behavior: normalize before uniqueness, then remove
  duplicate locations while preserving retained output spelling.
- PO7 confirms the patch preserves unrelated gettext behavior.
- F2 and F3 identify adjacent concerns that do not justify additional source
  edits for this issue.

## Next Iteration Inputs If More Work Is Requested

1. If maintainers want UUID de-duplication, provide a separate issue or public
   intent source that defines UUID identity and expected output.
2. If maintainers want Babel location wrapping or sorting changes, treat that as
   a separate PO writer behavior change and audit Babel callsites directly.
3. If a machine-checking environment is available, run the commands in
   `fvk/PROOF.md`; keep tests until the K claims return `#Top`.

## Source Patch Status

No V2 source edits were made during the FVK phase.
