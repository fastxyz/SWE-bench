# FVK Iteration Guidance: django__django-12713

Status: V1 stands unchanged.

## Source Decision

Keep the V1 source edit in `repo/django/contrib/admin/options.py`.

Reason:

- F-001 identifies the only prompt-derived bug: explicit `widget` was overwritten by admin many-to-many widget selection.
- OBL-001 is discharged by the V1 guard `if 'widget' not in kwargs:`.
- F-002 through F-004 and OBL-002 through OBL-006 show that default widget behavior, queryset behavior, through-model behavior, `formfield_overrides` precedence, and public override compatibility are preserved.

## No Additional Code Edits

No additional code edits are justified by the FVK findings.

Rejected follow-up changes:

- Changing `formfield_for_dbfield()` is not needed because OBL-005 confirms explicit kwargs already override `formfield_overrides`.
- Changing queryset handling is not needed because OBL-003 confirms the issue is widget precedence only and the queryset path is already guarded.
- Changing tests is forbidden by the task and not justified by F-005.

## Recommended Future Tests

Do not edit tests in this task. A future public test suite could add assertions that `formfield_for_manytomany(widget=CustomWidget)` preserves `CustomWidget` when the field is also configured in:

- `autocomplete_fields`
- `raw_id_fields`
- `filter_horizontal`
- `filter_vertical`

## Recommended Machine Check

When an execution environment with K exists, run:

```sh
cd fvk
kompile mini-admin-widget.k --backend haskell
kast --backend haskell admin-widget-spec.k
kprove admin-widget-spec.k
```

Until then, treat the proof as constructed, not machine-checked.
