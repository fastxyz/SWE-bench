# Baseline Notes

## Root cause

`DocstringSignatureMixin._find_signature()` only inspected `doclines[0]` for each
docstring and stopped after the first valid signature line.  That matched the
original single-signature convention but failed for SWIG-style overloaded
functions and methods whose docstrings begin with several consecutive signature
lines.  Only the first signature was moved into the generated directive header;
the remaining overload signatures stayed in the docstring body.

## Files changed

`repo/sphinx/ext/autodoc/__init__.py`

Added a plural signature collector for docstring signatures.  It scans the
start of each candidate docstring for consecutive lines matching the existing
Python signature regular expression and the current object name, strips all
matched lines from the emitted docstring body, and lets autodoc format multiple
matches as newline-separated signatures.  This reuses the directive header's
existing support for one signature per line and keeps the older
`_find_signature()` helper as a first-signature compatibility wrapper.

## Assumptions and alternatives

I assumed the overload signatures are contiguous at the start of a docstring,
which matches the issue description and the behavior documented for
`autodoc_docstring_signature`.  I did not scan later docstring paragraphs for
signature-looking lines because that could remove legitimate examples or prose.

I also kept the existing signature regular expression and object-name checks
unchanged.  Broadening the parser to accept more shapes of signatures would be a
separate behavior change and is not required for the reported overloaded-method
case.

I considered changing the base `Documenter.format_signature()` contract to
accept a list of signatures, but rejected that as a wider API change.  Formatting
the collected docstring signatures through the existing single-signature path
keeps event processing and directive output behavior aligned with current
autodoc behavior.
