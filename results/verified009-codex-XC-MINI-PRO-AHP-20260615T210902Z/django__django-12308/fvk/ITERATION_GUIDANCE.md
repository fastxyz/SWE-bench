# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not revise `repo/django/contrib/admin/utils.py` further. The FVK audit confirms that the V1 change matches the public intent and preserves adjacent admin behavior:

* F-001 and PO-1/PO-2 confirm the JSON repr bug is fixed by delegating non-null JSONField values to `prepare_value()`.
* F-002 and PO-3 confirm the InvalidJSONInput case is handled by delegation, not duplicated serialization.
* F-003 and PO-4 confirm the `models.JSONField` instance check covers subclasses without coupling admin to `contrib.postgres`.
* F-004 and PO-5 confirm the branch should remain after `value is None` to preserve admin empty display behavior.
* F-005 and PO-7 confirm no public API or caller protocol change is needed.

## Suggested Tests to Add or Keep

Do not edit tests in this task. A future test patch should cover:

* readonly admin display or `display_for_field()` for `models.JSONField()` with `{"foo": "bar"}` -> JSON text.
* `forms.InvalidJSONInput` passed through a JSONField display path unchanged.
* `django.contrib.postgres.fields.JSONField` using the same display path.
* `None` on JSONField still producing `empty_value_display`.

## Machine Check Follow-Up

When a K environment exists, run:

```sh
kompile fvk/mini-admin-display.k --backend haskell
kast --backend haskell fvk/admin-display-spec.k
kprove fvk/admin-display-spec.k
```

Only if `kprove` returns `#Top` should any unit tests covered exactly by these claims be considered redundant. Even then, integration/admin-rendering tests should be kept because the formal model covers only the display helper slice.
