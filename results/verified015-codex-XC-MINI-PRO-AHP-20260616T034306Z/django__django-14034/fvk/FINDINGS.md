# FVK Findings

Status: constructed from public intent and static source audit; no commands were
run.

## F1: V1 Discharges the Reported HTML Required-Attribute Bug

- Classification: confirmed fix, no further code change.
- Evidence: E1, E2, E3, PO-1, PO-2, PO-3.
- Input: parent `required=True`, `require_all_fields=False`, subfield required
  flags `[False, True]`, child widgets that both allow HTML `required`.
- Legacy observed behavior: rendered child required attrs `[True, True]`,
  because parent attrs were copied to all subwidgets.
- Expected behavior: `[False, True]`.
- V1 behavior by source reasoning: `MultiValueField.__init__()` sets child
  `is_required` to `[False, True]`; `MultiWidget.get_context()` rewrites child
  attrs to `widget.use_required_attribute(value) and widget.is_required`, giving
  `[False, True]`.
- Recommendation: keep V1 source unchanged for this obligation.

## F2: Validation Change Rejected

- Classification: intent conflict resolved by public discussion and docs.
- Evidence: E4, PO-6.
- Input: parent `required=False`, `require_all_fields=False`, all submitted
  subfield values empty.
- Observed behavior: valid at parent level, with `compress([])` as before.
- Expected behavior per final public issue discussion: unchanged; the composite
  optional field can be skipped entirely.
- Recommendation: do not edit `MultiValueField.clean()`.

## F3: Required-All Compatibility Preserved

- Classification: frame condition discharged.
- Evidence: E6, PO-4.
- Input: parent `required=True`, `require_all_fields=True`.
- Expected behavior: all subwidgets continue to render `required` when the
  parent required attr is present.
- V1 behavior by source reasoning: `MultiWidget.require_all_fields` defaults to
  true, so the partial-required override is inactive unless a `MultiValueField`
  explicitly sets it false.
- Recommendation: keep V1 source unchanged.

## F4: Optional Parent Rendering Preserved

- Classification: frame condition discharged.
- Evidence: E4, PO-5.
- Input: parent `required=False`, `require_all_fields=False`, some subfields
  individually required.
- Expected behavior: no HTML `required` is forced by the parent render path,
  because the whole composite can be skipped.
- V1 behavior by source reasoning: `BoundField.build_widget_attrs()` does not
  add parent `required`; child rendering therefore receives no parent required
  attr to split.
- Recommendation: keep V1 source unchanged.

## F5: Proof Is Constructed, Not Machine-Checked

- Classification: proof capability gap imposed by task constraints.
- Evidence: PO-8.
- Impact: no test removal is justified. The K commands are recorded in
  `PROOF.md` for a future environment.
- Recommendation: do not remove tests; add targeted rendering tests in a normal
  development environment, but do not modify tests in this task.
