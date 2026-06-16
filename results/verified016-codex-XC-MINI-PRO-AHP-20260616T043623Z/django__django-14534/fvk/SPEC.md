# FVK Specification: BoundWidget.id_for_label

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Target production code:

- `repo/django/forms/boundfield.py`, `BoundWidget.id_for_label`
- Producer contract used by the target: `repo/django/forms/widgets.py`, `ChoiceWidget.create_option()` and `Widget.get_context()`
- Rendering contract checked for compatibility: `repo/django/forms/templates/django/forms/widgets/input_option.html` and `select_option.html`

The audited observable is the value exposed by `BoundWidget.id_for_label` for a subwidget dictionary produced by Django's widget rendering pipeline.

## Intent Spec

I1. For an iterated checkbox or radio subwidget whose option-building data contains a rendered `attrs["id"]`, `BoundWidget.id_for_label` must return exactly that id.

I2. A custom form `auto_id` format is part of the rendered subwidget id. `BoundWidget.id_for_label` must not reconstruct a default `id_%s_%s` id that ignores the form's configured id format.

I3. If a subwidget has no rendered id, `BoundWidget.id_for_label` must not invent one. The correct label target is blank because there is no element id to target.

I4. The property must be a pure read of existing subwidget data. It must not mutate `self.data`, `self.data["attrs"]`, the parent widget, or renderer state.

I5. The fix must not change public signatures or dispatch shape. `BoundWidget.id_for_label` remains a property and `BoundWidget.tag()` rendering remains unchanged.

## Public Evidence Ledger

E1. Source: prompt. Quote: "widget['attrs']['id'] contains the 'id' we would like to use when rendering the label of our CheckboxSelectMultiple." Semantic obligation: return the already computed option id. Status: encoded in I1 and claim `ID-FOR-LABEL-PRESENT`.

E2. Source: prompt. Quote: "`BoundWidget.id_for_label()` is implemented as ... `return 'id_%s_%s' % ...` ignoring the id available through `self.data['attrs']['id']`." Semantic obligation: reject name/index reconstruction as the expected behavior. Status: encoded in I2 and Finding F-001.

E3. Source: prompt. Quote: "If however we do [override `auto_id`], one would assume that the method `BoundWidget.id_for_label` renders that string as specified through the `auto_id` format-string." Semantic obligation: custom `auto_id` must flow through `ChoiceWidget.create_option()` into `BoundWidget.id_for_label`. Status: encoded in I2 and proof obligation PO-003.

E4. Source: docs. Quote: "Each checkbox has an `id_for_label` attribute to output the element's ID." Semantic obligation: the property returns the actual element id, not a synthetic unrelated id. Status: encoded in I1 and I3.

E5. Source: implementation. `ChoiceWidget.create_option()` computes `option_attrs["id"] = self.id_for_label(option_attrs["id"], index)` when an id is present, then returns that attrs mapping in the subwidget data. Semantic obligation: the target function's input already contains the rendered id. Status: modeled in PO-002 and used in the proof.

E6. Source: implementation. `Widget.get_context()` and `ChoiceWidget.create_option()` always return subwidget data with an `attrs` mapping. Semantic obligation: `self.data["attrs"]` is a valid read for widget-produced subwidget data. Status: encoded in precondition P1.

E7. Source: public-test. Existing `test_iterable_boundfield_select` expects `fields[0].id_for_label == "id_name_0"` while the rendered tag is `<option value="john">John</option>` with no id. Semantic obligation: suspect legacy behavior because it expects an invented id with no rendered element id. Status: Finding F-002; not used as a correctness oracle.

## Preconditions

P1. `self.data` is a subwidget data dictionary produced by Django's widget rendering pipeline and contains an `attrs` mapping.

P2. `self.data["attrs"]` may contain key `"id"` with the actual rendered id value, or it may omit `"id"` when the rendered subwidget has no id.

No precondition is imposed on `self.data["name"]` or `self.data["index"]`; the corrected behavior is intentionally independent of those fields.

## Postconditions

PC1. If `"id"` is present in `self.data["attrs"]`, `BoundWidget.id_for_label == self.data["attrs"]["id"]`.

PC2. If `"id"` is absent from `self.data["attrs"]`, `BoundWidget.id_for_label == ""`.

PC3. The method does not mutate any state.

## Formal Spec English

Claim `ID-FOR-LABEL-PRESENT`: for any subwidget attrs map that contains key `"id"` with value `ID`, evaluating `idForLabel(attrs)` reaches result `ID`.

Claim `ID-FOR-LABEL-ABSENT`: for any subwidget attrs map that lacks key `"id"`, evaluating `idForLabel(attrs)` reaches result `""`.

Frame condition `ID-FOR-LABEL-PURE`: the attrs map is read only and no other state changes.

## Spec Audit

`ID-FOR-LABEL-PRESENT`: pass. It directly matches E1, E3, E4, and E5.

`ID-FOR-LABEL-ABSENT`: pass. It follows from E4: a label helper should output the element's id, and an element without a rendered id has no label target. E7 conflicts, but is suspect legacy behavior because it expects an id that the rendered `<option>` does not contain.

`ID-FOR-LABEL-PURE`: pass. The property is a read-only accessor and no public evidence asks it to mutate rendering data.

## Public Compatibility Audit

Changed public symbol: `BoundWidget.id_for_label`.

Signature and access shape: unchanged property. No added parameters, no changed call sites, no virtual dispatch changes.

Producer/consumer shape: unchanged. `BoundWidget.tag()` still renders the subwidget data via the parent widget template. Templates already use `widget.attrs.id` for generated label `for` attributes, so returning `attrs["id"]` aligns the accessor with rendered markup.

Known compatibility conflict: public test `test_iterable_boundfield_select` expects an invented id for a `<select>` option with no id. This is recorded as F-002 and rejected as legacy-derived because it contradicts the element-id contract.

## Formal Core

The mini-K core is in:

- `fvk/mini-django-boundwidget.k`
- `fvk/boundwidget-spec.k`

Exact commands to machine-check later are recorded in `fvk/PROOF.md`. They were not run.
