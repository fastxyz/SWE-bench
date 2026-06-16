# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional production code edits are justified by the FVK audit. The V1 guard
in `collect_pages()` is exactly at the page-emission boundary and discharges the
public intent: disabled EPUB builds yield no viewcode module pages, even with a
reused HTML-populated environment.

## Rationale

- F-001 and PO-002 show the original defect is page emission from stale module
  data during disabled EPUB builds. V1 prevents that emission before module data
  is inspected.
- PO-003 covers the `make html epub` reused-environment case by quantifying over
  whether module data exists.
- F-002, PO-004, and PO-005 show normal HTML builders and explicit EPUB opt-in
  still reach the existing generation path.
- F-003 shows clearing `_viewcode_modules` would be broader than the public
  intent and could affect other HTML-related builders that legitimately use the
  shared environment.
- PO-006 shows no public compatibility change is needed.

## Suggested Follow-up Tests

These are recommendations only; tests were not written or run.

- Build HTML first and then EPUB with `viewcode_enable_epub=False`; assert the
  EPUB output has no `_modules` viewcode pages.
- Build EPUB with `viewcode_enable_epub=True`; assert viewcode module pages are
  still produced.
- Build normal HTML with viewcode enabled; assert existing viewcode pages are
  unchanged.

## Commands for Future Machine Check

Do not run in this benchmark session. In an environment with K installed:

```sh
kompile fvk/mini-viewcode.k --backend haskell
kast --backend haskell fvk/viewcode-spec.k
kprove fvk/viewcode-spec.k
```

Expected result after resolving any local K path/setup details: all claims
reduce to `#Top`.
