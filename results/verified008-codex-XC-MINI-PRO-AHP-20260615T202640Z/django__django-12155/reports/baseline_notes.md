# Baseline Notes

## Root Cause

`django.contrib.admindocs.utils.trim_docstring()` computed the common
indentation across all non-empty lines in a docstring. For docstrings whose
summary starts on the first line, that first line has indentation `0`, so the
computed indent was always `0`. Later lines kept their function-body
indentation.

`parse_rst()` wraps admindocs text with a `default-role` directive. If a parsed
docstring body still starts with indentation, docutils can interpret that text
as directive content and raise `Error in "default-role" directive: no content
permitted.`

## Files Changed

`repo/django/contrib/admindocs/utils.py`

Replaced the local PEP 257 docstring trimming implementation with
`inspect.cleandoc()`, while preserving the existing guard that returns an empty
string for `None` and all-whitespace docstrings. `inspect.cleandoc()` ignores
the first line when calculating indentation for the remaining lines, which
handles both conventional Django-style docstrings with an empty first line and
docstrings whose summary begins immediately after the opening quotes.

`reports/baseline_notes.md`

Added this report with the root cause, the source change, and the reasoning
behind the chosen fix.

## Assumptions and Alternatives

I assumed admindocs should follow the PEP 257 docstring cleanup behavior already
referenced by the existing function comment, including support for first-line
summaries.

I considered changing the existing `min()` expression to skip `lines[0]` and
provide a default indentation of `0`. That would address the immediate bug, but
it would keep maintaining a local copy of logic that the standard library
already provides. Using `inspect.cleandoc()` is narrower and less error-prone.

I also considered changing `parse_rst()` to alter how the `default-role`
directive is wrapped, but rejected that because the invalid indentation is
introduced earlier by docstring cleanup and can affect every admindocs caller
that parses trimmed docstrings.
