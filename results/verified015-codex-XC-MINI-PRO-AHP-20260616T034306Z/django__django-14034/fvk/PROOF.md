# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Theorem

For the render-time path of a `MultiValueField` using `MultiWidget`:

1. If `required=True` and `require_all_fields=False`, each child subwidget's
   rendered HTML `required` attr equals
   `subwidget.use_required_attribute(value) and subfield.required`.
2. If `required=True` and `require_all_fields=True`, required-all rendering is
   preserved.
3. If `required=False`, the parent render path does not force child HTML
   `required` attrs.
4. Validation behavior is unchanged.

## Proof Sketch

PO-1 and PO-2 follow from `MultiValueField.__init__()` after V1. For each paired
`field, widget`, the assignment at `fields.py:1004` sets:

`widget.is_required = self.required and (self.require_all_fields or field.required)`

Case analysis:

- `self.required=True`, `self.require_all_fields=False` reduces to
  `field.required`.
- `self.required=True`, `self.require_all_fields=True` reduces to `True`.
- `self.required=False` reduces to `False`.

PO-3 follows from `MultiWidget.get_context()`. The existing parent attr path
still computes `widget_attrs` for each subwidget. V1 adds a branch guarded by
`not self.require_all_fields and widget_attrs.get('required')`. Inside that
branch, the rendered child attr becomes:

`widget.use_required_attribute(widget_value) and widget.is_required`

Composing PO-2 with PO-3 gives the partial-required theorem:

`widget.use_required_attribute(widget_value) and field.required`

for the parent-required, `require_all_fields=False` case.

PO-4 follows because `MultiWidget.require_all_fields` defaults to `True`, and
`MultiValueField.__init__()` also writes `True` for default required-all fields.
The new branch is therefore inactive; parent attrs keep flowing to all children.

PO-5 follows because `BoundField.build_widget_attrs()` still adds parent
`required` only when `self.field.required` is true. With an optional parent,
`widget_attrs.get('required')` is false or absent, so the partial-required branch
does not add any child required attr.

PO-6 follows by syntactic frame: V1 does not edit `MultiValueField.clean()`.

## K Claims

The constructed formal core is:

- `fvk/mini-django-forms.k`
- `fvk/multivalue-required-spec.k`

The key generic claim is:

`renderRequired(false, true, USES, setWidgetRequired(true, false, FIELDS))`
rewrites to `zipAnd(USES, FIELDS)`.

The reported concrete case instantiates:

- `USES = [true, true]`
- `FIELDS = [false, true]`
- result `[false, true]`

## Commands To Machine-Check Later

These commands were not run in this task:

```sh
cd fvk
kompile mini-django-forms.k --backend haskell
kast --backend haskell multivalue-required-spec.k
kprove multivalue-required-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`.

## Test Guidance

No tests are redundant because the proof is not machine-checked and the task
forbids editing tests. A future normal development pass should add rendering
tests for the mixed partial-required case, optional parent case, required-all
frame, and a child widget whose `use_required_attribute()` returns false.
