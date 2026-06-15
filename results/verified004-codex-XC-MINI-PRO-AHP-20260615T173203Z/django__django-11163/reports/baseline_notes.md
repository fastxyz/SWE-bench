# Baseline Notes

## Root cause

`django.forms.models.model_to_dict()` used a truthiness check for the optional
`fields` argument:

```python
if fields and f.name not in fields:
```

That treats an empty list the same as `None`. As a result,
`model_to_dict(instance, fields=[])` behaved as if no field filter had been
provided and returned all editable model fields instead of returning an empty
dictionary.

## Changed files

`repo/django/forms/models.py`

- Changed the `model_to_dict()` field filter to check `fields is not None`
  before testing field membership.
- This preserves the existing behavior for `fields=None`, while making any
  explicitly provided iterable, including an empty list, constrain the returned
  data.

`reports/baseline_notes.md`

- Added this report describing the diagnosis, source change, assumptions, and
  alternatives considered.

## Assumptions and alternatives considered

- I assumed the issue is limited to `model_to_dict()` because the problem
  statement names that function and its documented `fields` argument behavior.
- I considered changing other similar truthiness checks in
  `repo/django/forms/models.py`, such as form saving paths, but rejected that as
  broader than the reported issue and potentially behavior-changing outside the
  requested API surface.
- I assumed `exclude=[]` should continue to behave like no exclusions. The issue
  concerns an explicitly empty inclusion list, not an empty exclusion list.
- I did not modify tests because the task requires the fixed test suite to remain
  hidden and unchanged.
