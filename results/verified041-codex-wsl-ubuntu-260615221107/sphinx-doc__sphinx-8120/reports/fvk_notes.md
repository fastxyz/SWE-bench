# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-code issue requiring a V2
edit.

## Trace to findings and obligations

Kept the project-first `locale_dirs` order in `repo/sphinx/application.py`
because `fvk/FINDINGS.md` F-001 shows it resolves the reported
`locale/da/LC_MESSAGES/sphinx.mo` shadowing, and `fvk/PROOF_OBLIGATIONS.md`
PO-1 plus PO-2 discharge the project override winner rule.

Kept the built-in fallback order as `None` before the bundled package locale
because F-003 and PO-4 show this preserves V0 behavior when no project locale
directory supplies the message. Reordering package before system would be
unrelated to the issue and lacks public intent evidence.

Kept `sphinx.locale.init()` unchanged because F-004 and PO-6 show the helper's
existing first-catalog-wins semantics is the mechanism needed for the fix, and
changing it would broaden the behavior change to direct callers and extension
catalogs.

Kept the auto-build loop unchanged because PO-5 confirms it still runs before
the new lookup order is passed to `locale.init()`, so generated project
`sphinx.mo` files can participate in the override.

No tests, Python code, or K tooling were run. The proof artifacts are
constructed, not machine-checked, matching F-005 and the benchmark
instructions.
