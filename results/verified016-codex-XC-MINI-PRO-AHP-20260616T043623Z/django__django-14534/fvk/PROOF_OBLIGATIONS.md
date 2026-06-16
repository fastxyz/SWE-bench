# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## PO-001: Intent adequacy

Statement: The formal postcondition must use public intent as the source of truth, not V1 or legacy behavior.

Evidence: SPEC E1 through E4.

Discharge: The spec requires returning the subwidget attrs id when present and blank when absent. It rejects the old `id_%s_%s` reconstruction as the reported bug.

Status: discharged by adequacy audit in `fvk/SPEC.md`.

## PO-002: Data-shape precondition

Statement: For subwidgets produced by Django's widget pipeline, `self.data["attrs"]` exists and is a mapping.

Evidence: `Widget.get_context()` returns a `widget` dictionary with `attrs`; `ChoiceWidget.create_option()` returns option dictionaries with `attrs`.

Discharge: The target `BoundWidget` objects are constructed by `BoundField.subwidgets()` from `self.field.widget.subwidgets(...)`, which reaches these producer paths.

Status: discharged for widget-produced subwidgets. Residual trusted base recorded in F-003.

## PO-003: Present-id correctness

Statement: If `self.data["attrs"]` contains key `"id"` with value `ID`, `BoundWidget.id_for_label` returns `ID`.

Relevant K claim: `ID-FOR-LABEL-PRESENT` in `fvk/boundwidget-spec.k`.

Manual proof sketch: Python `dict.get("id", "")` returns the value associated with `"id"` when that key is present. Therefore V1 returns `ID`.

Status: constructed proof discharged.

## PO-004: Missing-id correctness

Statement: If `self.data["attrs"]` does not contain key `"id"`, `BoundWidget.id_for_label` returns `""`.

Relevant K claim: `ID-FOR-LABEL-ABSENT` in `fvk/boundwidget-spec.k`.

Manual proof sketch: Python `dict.get("id", "")` returns the default `""` when the key is absent. Therefore V1 does not invent a label target.

Status: constructed proof discharged.

## PO-005: Purity/frame condition

Statement: Evaluating `BoundWidget.id_for_label` does not mutate `self.data`, `self.data["attrs"]`, the parent widget, or the renderer.

Manual proof sketch: V1 consists of a single dictionary read. No assignment, update, method call on mutable renderer state, or parent-widget access occurs.

Status: discharged by code inspection.

## PO-006: Public compatibility

Statement: The repair must preserve the property shape and rendering call graph while aligning the property value with rendered markup.

Evidence: `BoundWidget.id_for_label` remains a property. `BoundWidget.tag()` and templates are unchanged. The templates already derive label `for` from `widget.attrs.id`.

Conflict: `test_iterable_boundfield_select` expects an invented id for an option without an id. This is suspect legacy behavior under F-002.

Status: discharged for public API shape; semantic legacy conflict recorded and intentionally not preserved.

## PO-007: Machine-check honesty

Statement: The proof must not claim machine-checked status and must include exact commands for later verification.

Discharge: `fvk/PROOF.md` lists `kompile`, `kast`, and `kprove` commands and labels all proof results constructed, not machine-checked.

Status: discharged.
