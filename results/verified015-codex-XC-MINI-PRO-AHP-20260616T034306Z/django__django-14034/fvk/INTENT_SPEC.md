# Intent Spec

Status: constructed from public/local evidence only.

## Required Behavior

I1. `MultiValueField(required=True, require_all_fields=False)` must render
HTML `required` per subfield. A subfield with `required=False` must not force
its subwidget to render `required`; a subfield with `required=True` may render
`required` when that subwidget can legally use the attribute.

I2. `MultiValueField(required=True, require_all_fields=True)` must preserve the
existing behavior where every subwidget participates in the required composite
value.

I3. `MultiValueField(required=False, require_all_fields=False)` must continue
to allow the whole composite field to be skipped; an all-empty value remains
valid at the parent level.

I4. The fix must not change validation semantics. The public issue discussion
identifies the validation path as intended for optional parent fields and
narrows the actionable problem to HTML `required` rendering.

I5. The fix must preserve public API compatibility: no changed method
signatures, no new required caller arguments, and no required changes to
`MultiWidget` subclasses.

