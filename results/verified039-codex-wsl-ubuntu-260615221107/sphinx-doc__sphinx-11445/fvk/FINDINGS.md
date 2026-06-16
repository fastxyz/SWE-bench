# FINDINGS

Status: constructed, not machine-checked. No tests or project code were run.

## F-001: Pre-V1 docinfo scan split a valid section title

Classification: resolved code bug.

Input: `content = [":mod:`mypackage2`", "=================", "", "Content"]`
and a non-empty `rst_prolog`.

Observed before V1: `docinfo_re` matched the first line, so
`prepend_prolog()` treated the title text as docinfo and inserted a generated
blank line plus the prolog before the underline. The title and underline were no
longer adjacent.

Expected: the role title line and underline remain adjacent; the prolog is
inserted before the complete heading.

Evidence: E1, E2, E3; proof obligations PO-002, PO-003, PO-004.

Resolution: V1 adds `_is_section_title()` and stops the docinfo scan when a
field-looking line is followed by a valid underline. No additional V2 source
change is required for this finding.

## F-002: V1 preserves genuine leading docinfo behavior

Classification: resolved compatibility/frame obligation.

Input: a leading metadata prefix such as `:title: test`, `:author: Sphinx team`
followed by non-docinfo content, with non-empty `rst_prolog`.

Observed in V1 by code inspection: each metadata line matches `docinfo_re`, and
`_is_section_title()` is false because the following line is not a valid section
underline for that metadata line. The scan therefore advances beyond the docinfo
prefix before inserting the prolog.

Expected: docinfo remains before the prolog, matching the documented metadata
behavior and the existing public unit-test shape.

Evidence: E5, E7; proof obligations PO-003, PO-005.

Resolution: V1 satisfies this frame condition.

## F-003: The section-title predicate is deliberately local

Classification: accepted scoped abstraction.

Input family: any field-looking line followed immediately by a repeated
non-alphanumeric, non-whitespace underline at least as long as the title.

Observed in V1 by code inspection: `_is_section_title()` returns true for this
family and false when there is no following line, when either line is empty after
normalization, when the underline is too short, or when the underline contains
multiple characters.

Expected: this is sufficient for the reported section-heading family and for the
local Sphinx documentation's section rule.

Evidence: E2, E6; proof obligations PO-002, PO-004.

Resolution: no source change. A broader docutils-complete parser model would be
an escalation, not required by the public issue.

## F-004: Proof artifacts are not machine-checked in this session

Classification: proof honesty / test guidance.

Input: the FVK proof package.

Observed: this benchmark forbids running K tooling, tests, Python, or project
code. The proof is constructed from source inspection and the K-style artifacts
only.

Expected: do not delete or weaken tests based on this proof unless the emitted
`kompile` and `kprove` commands are run later and return `#Top`.

Evidence: FVK docs; proof obligation PO-008.

Resolution: keep all tests. No test files were modified.

