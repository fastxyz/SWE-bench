# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Intent-derived domain

`content` is a mutable sequence of reStructuredText source lines represented by
`docutils.statemachine.StringList`; `prolog` is the configured `rst_prolog`
string. The in-domain cases include empty content, content with genuine leading
docinfo, ordinary content with no docinfo, and content whose first section title
starts with an inline domain role.

Status: discharged by `SPEC.md` C-EMPTY-PROLOG, C-NO-DOCINFO,
C-DOCINFO-PREFIX, and C-ROLE-TITLE.

## PO-002: Section predicate adequacy

When a field-looking line is followed by a valid section underline, it must be
treated as title text for insertion-position purposes, not as docinfo.

Status: discharged by `_is_section_title()` and `SPEC.md` C-SECTION-PREDICATE.
Trace: F-001 and F-003.

## PO-003: Docinfo scan invariant

During the scan loop in `prepend_prolog()`, `pos` equals the number of leading
lines already proven to be docinfo and not section-title lines. At loop exit,
`pos` is the first index that is out of range, not docinfo, or a section title.

Status: discharged by code inspection of the loop condition:
`docinfo_re.match(line) and not _is_section_title(content, pos)`.
Trace: F-001 and F-002.

## PO-004: Reported role-title case

For `content[0] == ":mod:`mypackage2`"` and
`content[1] == "================="`, with non-empty prolog, the final line list
must contain `":mod:`mypackage2`"` immediately followed by
`"================="`.

Status: discharged. `_is_section_title(content, 0)` is true, so the scan exits
at `pos == 0`; insertion happens before the title. Trace: F-001.

## PO-005: Genuine docinfo compatibility

For a leading docinfo prefix that is not a section title, the prolog must still
be inserted after the prefix with generated blank-line separators.

Status: discharged by the same scan invariant. Trace: F-002.

## PO-006: Empty or falsey prolog frame condition

If `prolog` is falsey, `prepend_prolog()` must not mutate `content`.

Status: discharged by the outer `if prolog:` guard.

## PO-007: Public API compatibility

No public signature, return type, override contract, or caller protocol may be
changed.

Status: discharged. V1 adds only a private helper and changes the internal scan
condition in `prepend_prolog()`; `RSTParser.decorate()` and public call sites
continue to call `prepend_prolog(content, self.config.rst_prolog)`.

## PO-008: Verification honesty

The proof must be labeled constructed, not machine-checked, and must not justify
test deletion in this no-execution benchmark session.

Status: discharged by `PROOF.md`, `FINDINGS.md` F-004, and
`ITERATION_GUIDANCE.md`.

