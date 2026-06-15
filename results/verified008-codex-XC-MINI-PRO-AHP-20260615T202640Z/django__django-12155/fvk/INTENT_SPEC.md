# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Scope

The audited production behavior is `django.contrib.admindocs.utils.trim_docstring()`
and the admindocs parsing path that passes its output to `parse_rst()`.

## Required Behaviors

I1. `trim_docstring(None)` and all-whitespace docstrings return the empty
string.

Evidence: existing code guard, public callsites that pass `__doc__`, and
admindocs' need to tolerate missing docstrings.

I2. A docstring whose summary starts on the first physical line is in scope.
Its first line must not force the common indentation margin for later lines to
zero.

Evidence: `benchmark/PROBLEM.md`: "usually the docstring text starts at the
first line" and "The problem is that the indentation of the first line is 0."

I3. For non-empty docstrings, cleanup must follow the PEP 257 indentation
algorithm: left-trim the first line, compute the common margin from non-empty
lines after the first line, dedent later lines by that margin, and remove
surrounding blank space from the cleaned docstring.

Evidence: the function comment says it is based on PEP 257 handling of
docstring indentation; the public hint says to switch to `inspect.cleandoc()`
because it implements that algorithm.

I4. One-line docstrings and docstrings with no non-empty lines after the first
line must not raise `ValueError`.

Evidence: the public hint rejects the naive `min(lines[1:])` edit because it
"crashes for some tests with ValueError: min() arg is an empty sequence."

I5. The cleaned text passed into `parse_rst()` must not retain function-body
indentation solely because the summary line had indentation `0`; otherwise
docutils can treat that indented text as content of Django's injected
`default-role` directive.

Evidence: the issue reports `Error in "default-role" directive: no content
permitted` and identifies `trim_docstring()` as the culprit.

I6. Existing Django-style docstrings whose first physical line is empty must
continue to clean to the documented admindocs text.

Evidence: public in-repository tests in `repo/tests/admin_docs/test_utils.py`
cover the leading-empty-line docstring style and expected parsed output.

I7. The public API shape must remain compatible: `trim_docstring(docstring)`
continues to accept a docstring-like value or `None` and returns a string. Its
callers do not need signature or return-shape changes.

Evidence: all admindocs callsites use the existing one-argument helper and
consume a string result.
