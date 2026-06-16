# Baseline Notes

## Root Cause

`sphinx.util.rst.prepend_prolog()` scans the start of a document for leading
docinfo fields so it can insert `rst_prolog` after them. The scan used
`docinfo_re` alone, and that expression also matches a section title that starts
with an inline domain role, such as `:mod:`mypackage2``. When such a title is the
first line of a document, Sphinx incorrectly treats the title line as docinfo,
inserts a generated blank line and the `rst_prolog` after it, and separates the
title text from its underline. Docutils then no longer recognizes the title, so
the document title is missing from rendered output and toctrees.

## Files Changed

`repo/sphinx/util/rst.py`

Added a small `_is_section_title()` helper that checks whether a field-looking
line is immediately followed by a section underline. `prepend_prolog()` now
stops the docinfo scan when a matching line is actually a section title, causing
`rst_prolog` to be inserted before the title instead of between the title and
underline. This keeps the existing behavior for normal leading docinfo fields and
does not affect `rst_epilog`.

## Assumptions

The intended behavior is that `rst_prolog` should be inserted after genuine
top-of-file docinfo, but never between a section title and its underline. The
section-title check intentionally mirrors the simple shape needed by docutils'
underlined titles: a non-empty line followed by a repeated non-alphanumeric,
non-whitespace underline that is at least as long as the title text.

## Alternatives Considered

One alternative was to narrow `docinfo_re` so it only matches field markers whose
body starts with whitespace or end-of-line. That would fix `:mod:`...`` titles,
but it changes docinfo recognition more broadly and risks missing existing
metadata forms that the previous implementation accepted. A title-aware guard is
more targeted: it only changes behavior when the next line shows that the
field-looking text belongs to a section heading.

Another alternative was to always add another blank line around `rst_prolog`.
That does not address the misclassification of the title line as docinfo, and it
would still leave the prolog inserted after the first title line rather than
before the complete title.
