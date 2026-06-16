# FVK Specification: django__django-16667

Status: constructed, not machine-checked.

Target: `SelectDateWidget.value_from_datadict(data, files, name)` in `repo/django/forms/widgets.py`.

## Scope

The audited unit is the public widget method that reconstructs a date value from split request fields. The method has no loops or recursion, so the FVK proof is a straight-line branch proof over the observable return value and escaping exceptions. `files` is unused by this method and is a frame condition.

The input domain is fixed from public intent: request `GET` or `POST` data supplying string values for `name_year`, `name_month`, and `name_day`, with components potentially absent or blank. Arbitrary mapping objects with non-string values or side-effecting `get()` implementations are outside this issue-driven domain.

## Public Intent Ledger

E-001

- Source: prompt.
- Evidence: "SelectDateWidget can crash with OverflowError."
- Obligation: user-controlled date components must not make form validation crash with an uncaught `OverflowError`.
- Status: encoded by PO-001 and F-001.

E-002

- Source: prompt.
- Evidence: "The issue happens as part of the validation logic run in form.is_valid".
- Obligation: malformed split date input should continue into normal form validation, not terminate the request with a server error.
- Status: encoded by PO-001 and PO-002.

E-003

- Source: prompt.
- Evidence: "y, m and d are user controlled" and the shown constructor call `datetime.date(int(y), int(m), int(d))`.
- Obligation: the complete-triple path must account for exceptions raised while converting submitted date components into a Python `date`.
- Status: encoded by PO-001 and PO-002.

E-004

- Source: implementation comment.
- Evidence: "Return pseudo-ISO dates with zeros for any unselected values, e.g. '2017-0-23'."
- Obligation: invalid complete triples are represented as pseudo-ISO strings, preserving invalid component information for downstream validation.
- Status: encoded by PO-002.

E-005

- Source: public tests.
- Evidence: visible `test_value_from_datadict()` expects valid triples to produce formatted dates, partially blank complete triples to produce pseudo-ISO values, all blanks to produce `None`, and missing components to fall back to `data.get(name)`.
- Obligation: the overflow fix must not change these existing branches.
- Status: encoded by PO-003, PO-004, and PO-005.

E-006

- Source: public API shape.
- Evidence: `SelectDateWidget` is a public widget class and `value_from_datadict(data, files, name)` is called by form binding code and wrappers.
- Obligation: do not change the method signature, return-value categories, or caller protocol.
- Status: encoded by PO-006.

## Intended Contract

For request-style string data:

1. If `name_year`, `name_month`, and `name_day` are all present as the empty string, return `None`.
2. If all three component keys are present:
   - If integer conversion and Python `datetime.date()` construction succeed, return the date formatted with Django's first `DATE_INPUT_FORMATS` entry after `sanitize_strftime_format()`.
   - If integer conversion or date construction raises `ValueError`, return the existing pseudo-ISO string `"%s-%s-%s" % (y or 0, m or 0, d or 0)`.
   - If date construction raises `OverflowError`, return the same pseudo-ISO string and do not let the exception escape.
3. If at least one component key is missing and the all-empty case did not apply, return `data.get(name)`.
4. Preserve the public method signature and the existing valid-date, invalid-date, blank, and fallback behavior.

## Formalization Notes

The `.k` artifacts model only the branch structure and exception classes relevant to the audited method. They abstract Django formatting and Python date construction into predicates:

- `validComplete(Y, M, D)` means the complete triple converts to a valid Python date.
- `valueErrorComplete(Y, M, D)` means the complete triple follows the existing invalid-date `ValueError` path.
- `overflowComplete(Y, M, D)` means the complete triple raises the reported Python date `OverflowError`.

These predicates are mutually exclusive classification assumptions for the request-string domain. The model keeps the property under verification observable: the returned value distinguishes formatted dates, pseudo-ISO invalid dates, `None`, and fallback values.

