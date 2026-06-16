# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not identify a source-code problem that
requires a V2 edit.

## Trace to Findings and Proof Obligations

`repo/sphinx/util/rst.py` was left unchanged because F-001 identifies the actual
pre-V1 bug as insertion between a field-looking role title and its underline,
and PO-002, PO-003, and PO-004 show that V1 discharges that obligation. The
critical point is that `:mod:`...`` may still match `docinfo_re`; V1 is correct
because `_is_section_title()` makes that line stop the docinfo scan when the next
line is a valid underline.

The docinfo behavior was also left unchanged. F-002 and PO-005 trace the
compatibility obligation from the field-list documentation and existing public
unit-test shape: genuine top-of-file metadata still remains before the prolog.
Changing `docinfo_re` would be broader than necessary and could alter metadata
recognition outside the reported defect.

The section-title helper was kept as implemented. F-003 and PO-002 justify the
helper's local predicate from the Sphinx reStructuredText documentation: a
section header is title text underlined by a punctuation character at least as
long as the text. The helper is private, and PO-007 confirms that no public API
or parser call protocol changed.

No tests were modified or removed. F-004 and PO-008 require the proof to remain
honest: this session cannot run tests, Python, or K tooling, so all proof
artifacts are constructed but not machine-checked.

## Artifacts Written

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK documentation also requires supporting adequacy and formal-core files,
so these were added under `fvk/` as well:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-rst-prolog.k`
- `fvk/prepend-prolog-spec.k`

## Verification Status

No commands were executed beyond file inspection and editing. The emitted future
machine-check commands are recorded in `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md`; they must be run in a real K environment before the
proof is treated as machine-verified.

