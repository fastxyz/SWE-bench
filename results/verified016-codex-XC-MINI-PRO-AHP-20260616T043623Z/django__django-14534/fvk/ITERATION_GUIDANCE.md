# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

V1 stands unchanged.

The audit found that the V1 expression:

```python
return self.data['attrs'].get('id', '')
```

is the minimal repair that satisfies the intent-derived contract:

- It fixes F-001 by returning the rendered option id when present.
- It satisfies PO-003 for custom `auto_id` propagation.
- It satisfies PO-004 by returning blank when there is no rendered id.
- It avoids the legacy fallback rejected in F-002.

## Do Not Apply

Do not add a fallback to `'id_%s_%s' % (self.data["name"], self.data["index"])`.

Reason: that fallback is the reported bug for custom `auto_id` and also produces ids that need not exist in rendered markup. It would fail PO-003 for custom id formats and PO-004 for missing-id subwidgets.

Do not change `ChoiceWidget.create_option()` or the widget templates.

Reason: the producer already computes the rendered id in `attrs["id"]`, and templates already use `widget.attrs.id`. The mismatch was isolated to the `BoundWidget.id_for_label` accessor.

## Suggested Tests for a Normal Django Workflow

The current task forbids test edits, but a normal follow-up should cover:

- `CheckboxSelectMultiple` with `auto_id="%s_id"`: each iterated checkbox `id_for_label` equals the rendered input id, such as `composers_id_0`.
- `RadioSelect` with a custom `auto_id`: each iterated radio `id_for_label` equals the rendered input id.
- A subwidget without a rendered id, such as a select option under `auto_id=False`, exposes `id_for_label == ""` rather than an invented id.

## Commands for Later

Do not run these in this workspace. They are recorded for a future environment with K installed:

```sh
kompile fvk/mini-django-boundwidget.k --backend haskell
kast --backend haskell fvk/boundwidget-spec.k
kprove fvk/boundwidget-spec.k
```

Keep integration tests until a real machine check returns `#Top` and until full Django renderer coverage is separately addressed.
