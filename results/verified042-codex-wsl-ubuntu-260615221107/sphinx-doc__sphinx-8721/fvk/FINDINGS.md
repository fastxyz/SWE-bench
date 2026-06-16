# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations. No tests or
project code were executed.

## Findings

### F-001: Pre-fix page generation for disabled EPUB violates public intent

Input/state:

- `app.builder.name == "epub"` or otherwise starts with `epub`
- `env.config.viewcode_enable_epub == False`
- `env._viewcode_modules` already contains entries from a preceding HTML build

Observed before V1:

`collect_pages()` lacked an EPUB-disabled guard, so it would iterate the cached
modules and yield module pages plus the `_modules/index` page.

Expected:

No viewcode page tuples should be yielded for EPUB by default.

Evidence:

- `benchmark/PROBLEM.md`: expected behavior is "module pages should not be
  created for epub by default."
- `repo/doc/usage/extensions/viewcode.rst`: "By default `epub` builder doesn't
  support this extension."

Classification: code bug in the page-emission boundary.

Proof obligations: PO-002 and PO-003.

Status after audit: fixed by V1. The guard in `collect_pages()` returns before
module cache inspection for all disabled EPUB states.

### F-002: V1 preserves non-EPUB and explicit EPUB opt-in behavior

Input/state:

- non-EPUB HTML-related builder with module entries, or
- EPUB builder with `viewcode_enable_epub == True` and module entries

Observed in V1:

The new guard condition is false, so control falls through to the pre-existing
module-page generation logic.

Expected:

Normal HTML-related builders and explicitly enabled EPUB builds should keep
viewcode generation behavior.

Evidence:

- Viewcode docs say it works on HTML-related builders except `singlehtml`.
- Viewcode docs say setting `viewcode_enable_epub` true enables the extension
  for EPUB.

Classification: frame condition checked, no code bug found.

Proof obligations: PO-004 and PO-005.

Status after audit: discharged by inspection and by the K frame claims.

### F-003: Clearing `_viewcode_modules` would be broader than the intent

Candidate alternative:

Clear or mutate `env._viewcode_modules` during disabled EPUB builds.

Rejected because:

The public intent only requires EPUB not to create module pages by default.
The environment may be shared with other HTML-related builders, and the docs
still support viewcode for those builders and for EPUB opt-in.

Classification: rejected alternative, not a code change.

Proof obligations: PO-004, PO-005, and PO-006.

Status after audit: V1's local generation guard is preferred.

### F-004: No execution-based validation is available in this benchmark phase

Input/state:

The task explicitly says no execution environment exists and forbids tests,
Python, and K tool execution.

Observed:

The proof is constructed but not machine-checked; no runtime test output exists.

Expected:

Artifacts must include commands and reason about expected outcomes without
executing them.

Classification: proof honesty and test gap.

Proof obligations: PO-007.

Status after audit: recorded; all proof claims are labeled constructed, not
machine-checked.

## Open Findings

None for the issue intent. V1 stands unchanged.
