# SPEC: rst_prolog Title Preservation

Status: constructed, not machine-checked.

## Scope

The audited unit is `sphinx.util.rst.prepend_prolog(content, prolog)` plus the
private helper `_is_section_title(content, pos)` added in V1. The observable
property is the order of lines presented to docutils after Sphinx inserts
`rst_prolog`.

## Intent-Only Contract

For any non-empty `rst_prolog`, Sphinx must include the prolog at the beginning
of every source file, except that existing top-of-file docinfo fields remain
before the prolog. The insertion must not split a reStructuredText section title
from its underline. In particular, a field-looking inline role title such as
`:mod:`mypackage2`` followed by a section underline is a title, not docinfo for
the purpose of choosing the insertion point.

If `prolog` is falsey, `prepend_prolog()` leaves `content` unchanged.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Using rst_prolog removes top level headings containing a domain directive" | A first heading that starts with a domain role remains a rendered heading and toctree title when `rst_prolog` is set. | Encoded in C-ROLE-TITLE. |
| E2 | prompt | `:mod:`mypackage2`` followed by `=================` | Field-looking inline-role text followed by an underline is an in-domain section title. | Encoded in C-SECTION-PREDICATE and C-ROLE-TITLE. |
| E3 | prompt hint | "the prolog is inserted between `:mod:`...` and the header definition" | The repair must prevent insertion between title text and underline. | Encoded in C-ROLE-TITLE. |
| E4 | docs | `rst_prolog` is "included at the beginning of every source file" | For ordinary content without docinfo, prolog lines precede original content and are followed by a separator blank. | Encoded in C-NO-DOCINFO. |
| E5 | docs | "A field list near the top of a file is normally parsed by docutils as the docinfo" | Genuine leading docinfo stays before the prolog. | Encoded in C-DOCINFO-PREFIX. |
| E6 | docs | Section headers are created by underlining the section title with a punctuation character "at least as long as the text" | `_is_section_title()` may classify a line as title text when the next line is a repeated punctuation underline at least as long as the title. | Encoded in C-SECTION-PREDICATE. |
| E7 | public tests | Existing tests assert prolog insertion after docinfo and at start when no docinfo exists. | These support frame conditions for legacy intended behavior, but they do not override E1-E3. | Encoded in C-DOCINFO-PREFIX and C-NO-DOCINFO. |

## Formal Claims

The K-style formal artifacts are `mini-rst-prolog.k` and
`prepend-prolog-spec.k`. They model the line list, the docinfo scan, and prolog
insertion position. The model abstracts docutils parsing to the exact property
under audit: adjacency of a section title line and its underline.

### C-SECTION-PREDICATE

For any position `i`, `_is_section_title(content, i)` returns true only when:

- `i + 1 < len(content)`;
- `content[i]` is non-empty after trailing whitespace is ignored;
- `content[i + 1]` is non-empty after surrounding whitespace is ignored;
- the stripped underline is at least as long as the title text;
- the underline consists of one repeated non-alphanumeric, non-whitespace
  character.

This is sufficient for the issue family because local Sphinx docs define section
headers as title text underlined by a punctuation character at least as long as
the text.

### C-SCAN-POSITION

The scan loop in `prepend_prolog()` computes the least index `pos` such that
one of these is true:

- `pos == len(content)`;
- `content[pos]` does not match `docinfo_re`;
- `_is_section_title(content, pos)` is true.

For every index before `pos`, the line matches `docinfo_re` and is not a section
title.

### C-ROLE-TITLE

For any content whose first line is field-looking role title text and whose
second line is a valid underline for that title, the scan stops at `pos == 0`.
For non-empty prolog, the result starts with the prolog block, then a generated
blank line, then the original title line immediately followed by the original
underline line.

### C-DOCINFO-PREFIX

For any genuine leading docinfo prefix with no section title inside the prefix,
the scan advances past the prefix. For non-empty prolog, the result preserves the
docinfo prefix, inserts a generated blank line, inserts the prolog block, inserts
another generated blank line, and then preserves the original suffix unchanged.

### C-NO-DOCINFO

For any content whose first line is neither docinfo nor a field-looking section
title, the scan stops at `pos == 0`. For non-empty prolog, the result starts
with the prolog block and a generated blank line, followed by the original
content unchanged.

### C-EMPTY-PROLOG

If `prolog` is falsey, `prepend_prolog()` does not mutate `content`.

## Adequacy Decision

V1 satisfies the intent-derived claims. The key proof obligation is not that
`:mod:`...`` fails `docinfo_re`; it still matches the broad regex. The obligation
is that a matching line followed by a section underline terminates the docinfo
scan before the prolog is inserted. V1 does exactly that, so no V2 source change
is required.

