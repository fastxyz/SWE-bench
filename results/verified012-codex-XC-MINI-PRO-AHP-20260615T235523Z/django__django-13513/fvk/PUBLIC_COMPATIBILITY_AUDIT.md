# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol Surface

- `ExceptionReporter.get_traceback_frames()` keeps the same signature and still returns a list of frame dictionaries.
- The nested helper `explicit_or_implicit_cause()` is not a public symbol.
- The frame dictionary still contains `exc_cause` and `exc_cause_explicit`.

## Callsite And Consumer Search

Searches performed by static inspection only:

- `rg -n "get_traceback_frames\\(|exc_cause_explicit|exc_cause" repo/django repo/docs`
- `rg -n "DEFAULT_EXCEPTION_REPORTER|ExceptionReporter|get_traceback_data|get_traceback_frames" repo/docs repo/django/conf repo/django/views/debug.py`

Findings:

- In-repo consumers of `exc_cause` and `exc_cause_explicit` are the technical 500 HTML and text templates.
- The templates use `exc_cause_explicit` as a boolean branch condition.
- Django documents `ExceptionReporter` subclassing through `get_traceback_data()`, but no public documentation found in this workspace promises the raw type of `exc_cause_explicit`.

## Compatibility Result

The V2 source edits preserve public call signatures and frame keys. Converting `exc_cause_explicit` from a truthy object-or-`None` value to a boolean preserves the observed template contract and makes the key match its flag name. No compatibility blocker was found.
