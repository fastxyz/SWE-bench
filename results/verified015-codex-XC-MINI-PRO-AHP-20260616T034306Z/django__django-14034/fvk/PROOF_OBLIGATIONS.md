# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Parent and Child Required State Are Separate

- Source: E3.
- Claim: `MultiValueField.__init__()` must keep parent required state and child
  subfield required state separately representable for rendering.
- Discharge: V1 stores `self.widget.require_all_fields` and sets each child
  widget's `is_required` from `self.required` and the corresponding field's
  `required` flag.
- Result: discharged.

## PO-2: Partial-Required Propagation

- Source: E1, E5.
- Claim: for `require_all_fields=False`, direct child widget required state is
  `parent_required and field.required`.
- Discharge: `fields.py:1004` assigns exactly this expression.
- Result: discharged.

## PO-3: Partial-Required Rendering

- Source: E2, E7.
- Claim: when a parent required attr is present and `require_all_fields=False`,
  the rendered child required attr is
  `child_widget.use_required_attribute(child_value) and child_widget.is_required`.
- Discharge: `widgets.py:848` implements exactly this branch.
- Result: discharged.

## PO-4: Required-All Frame

- Source: E6.
- Claim: default `require_all_fields=True` rendering remains uniform.
- Discharge: `MultiWidget.require_all_fields` defaults to true and the new
  branch only runs when it is false.
- Result: discharged.

## PO-5: Optional Parent Frame

- Source: E4.
- Claim: an optional parent does not force child HTML required attrs from this
  render path.
- Discharge: unchanged `BoundField.build_widget_attrs()` only adds `required`
  when `self.field.required` is true.
- Result: discharged.

## PO-6: Validation Frame

- Source: E4.
- Claim: `MultiValueField.clean()` behavior is unchanged.
- Discharge: V1 edits only `__init__()` and `MultiWidget.get_context()`, not the
  validation method.
- Result: discharged.

## PO-7: Public Compatibility

- Source: I5 and compatibility audit.
- Claim: no public signature, call shape, or subclass override contract changes.
- Discharge: V1 adds an optional class attribute and internal state assignment
  only; method signatures are unchanged.
- Result: discharged.

## PO-8: Machine Check Honesty

- Source: task no-execution rule.
- Claim: all proof claims must be labeled constructed, not machine-checked.
- Discharge: `PROOF.md`, `FINDINGS.md`, and the `.k` files record commands but
  no command output.
- Result: discharged.

