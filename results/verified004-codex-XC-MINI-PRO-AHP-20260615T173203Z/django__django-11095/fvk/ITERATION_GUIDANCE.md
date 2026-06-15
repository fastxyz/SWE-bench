# Iteration Guidance

Status: constructed, not machine-checked.

## Source Changes Made in V2

V2 keeps the requested hook and reverts the unrelated `to_field_allowed()`
change from V1:

- Keep `ModelAdmin.get_inlines(request, obj=None)`.
- Keep `get_inline_instances()` iterating over
  `self.get_inlines(request, obj)`.
- Restore `to_field_allowed()` to iterate over static `admin.inlines`.

This resolves Finding F-001 and discharges PO-004.

## Source Changes Not Made

- No changes to `django.contrib.admin.checks.py`. PO-006 and F-003 justify
  keeping checks static.
- No changes to tests. The task forbids modifying test files.
- No docs or release notes changes. The benchmark task asks for source and FVK
  artifacts; docs are noted as future project work, not required for the hidden
  test suite.

## Suggested Future Public Tests

Future tests, outside this task's constraints, should cover:

- overriding `get_inlines(request, obj)` to return different inline classes for
  add vs. change;
- proving `get_inline_instances()` passes the same `request` and `obj`;
- preserving permission filtering when dynamic inline classes are returned.

## Next Verification Step

In an environment with K installed, run:

```sh
kompile fvk/mini-django-admin.k --backend haskell
kast --backend haskell fvk/modeladmin-inlines-spec.k
kprove fvk/modeladmin-inlines-spec.k
```

Until those commands return `#Top`, treat the proof as constructed, not
machine-checked.
