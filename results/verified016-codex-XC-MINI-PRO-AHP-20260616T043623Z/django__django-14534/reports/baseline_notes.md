# Baseline Notes

## Root cause

`BoundField.subwidgets` asks the parent choice widget to build each subwidget. During that path, `ChoiceWidget.create_option()` computes the final per-option `attrs` dictionary and, when an id is available, stores the actual rendered id in `attrs["id"]`.

`BoundWidget.id_for_label` ignored that computed value and rebuilt an id from `self.data["name"]` and `self.data["index"]`. That only matched the default `auto_id="id_%s"` shape. With a custom `auto_id` such as `"%s_id"`, rendered checkbox/radio inputs received ids like `field_id_0`, while `BoundWidget.id_for_label` returned `id_field_0`.

## Changed files

`repo/django/forms/boundfield.py`

Changed `BoundWidget.id_for_label` to return the id already present in `self.data["attrs"]`, with an empty-string fallback when a subwidget has no id. This makes the property match the actual rendered subwidget markup and preserves widgets that intentionally render no label target.

## Assumptions

The correct label target for a `BoundWidget` is the id that the widget option-building code has already computed, not a second reconstruction based on field name and option index.

`attrs` is always present in choice widget option data produced by `ChoiceWidget.create_option()`, so reading `self.data["attrs"]` is consistent with the existing subwidget data contract.

No tests or project code were run, per the task instructions.

## Alternatives considered

Keeping the old generated-id fallback would preserve historical output for subwidgets with no id, but it would continue to expose ids that are not present in rendered markup. I rejected that because `BoundWidget.id_for_label` should not invent a label target.

Changing `ChoiceWidget.create_option()` or the checkbox/radio templates would be broader than necessary. The rendered inputs already receive the correct ids; only `BoundWidget.id_for_label` was out of sync.
