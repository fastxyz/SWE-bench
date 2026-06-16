# Formal Spec English

This is the English paraphrase of the K claims in
`fvk/multivalue-required-spec.k`.

## C1: Propagate Child Required State

For each paired subfield/subwidget in a `MultiValueField` using a `MultiWidget`,
the child widget's `is_required` is set to:

- `parent_required` when `require_all_fields=True`;
- `parent_required and subfield_required` when `require_all_fields=False`.

## C2: Render Partial Required Attributes

When a parent required attribute is present and `require_all_fields=False`, each
rendered child receives HTML `required` exactly when both conditions hold:

- the corresponding child widget can use the HTML required attribute for its
  value; and
- that child widget is marked required by C1.

## C3: Preserve Required-All Rendering

When `require_all_fields=True`, the partial-required override is inactive. The
parent `required` attribute continues to be copied to all subwidgets, preserving
the existing required-all rendering behavior.

## C4: Optional Parent Rendering

When the parent field is optional, the parent required attribute is absent.
Therefore no child subwidget receives HTML `required` from this path, even if a
subfield is individually required for partial-value validation.

## C5: Validation Frame

No formal claim rewrites `MultiValueField.clean()` behavior. The proof only
covers initialization of render-time widget state and child-attribute rendering.

