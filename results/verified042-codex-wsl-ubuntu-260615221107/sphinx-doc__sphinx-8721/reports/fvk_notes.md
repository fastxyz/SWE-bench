# FVK Notes

The FVK audit confirms V1 and does not justify further production code edits.

Decision D-001: keep the V1 `collect_pages()` guard unchanged.

Trace: F-001 identifies the original defect as disabled EPUB page emission from
an already-populated `_viewcode_modules` cache. PO-002 proves disabled EPUB
emits no pages, and PO-003 proves that this holds regardless of whether module
data exists. The V1 guard is therefore sufficient for the reported `make html
epub` path.

Decision D-002: do not clear or mutate `_viewcode_modules`.

Trace: F-003 rejects environment clearing as broader than public intent. PO-004
and PO-005 require preserving normal HTML generation and explicit EPUB opt-in,
so the local page-generation guard is the narrower fix.

Decision D-003: do not change event registration or public APIs.

Trace: F-002 shows fallthrough behavior is preserved where the disabled EPUB
guard is false. PO-006 records that the function signature, generator protocol,
and `html-collect-pages` registration remain compatible.

Decision D-004: add FVK artifacts and keep proof claims honest.

Trace: F-004 and PO-007 require a constructed, not machine-checked proof because
the benchmark forbids execution. The artifacts under `fvk/` include the five
requested Markdown files plus `mini-viewcode.k` and `viewcode-spec.k` so the
formal core can be machine-checked later.

No tests or project code were executed, and no test files were modified.
