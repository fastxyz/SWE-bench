# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no justified source edit beyond the existing change in `repo/django/forms/boundfield.py`.

## Trace to Findings and Proof Obligations

F-001 identifies the original bug: `BoundWidget.id_for_label` reconstructed `id_%s_%s` and ignored the option id that `ChoiceWidget.create_option()` had already computed. PO-003 requires returning `self.data["attrs"]["id"]` when present. V1 satisfies that with `self.data["attrs"].get("id", "")`.

F-002 identifies the only compatibility conflict found during the audit: one public select-option test expects an invented id even when the rendered `<option>` has no id. PO-004 requires the missing-id case to return `""`, and PO-006 classifies the old select expectation as legacy-derived rather than intent-derived. I therefore did not add a fallback to the old `id_%s_%s` reconstruction.

F-003 records the proof capability gap: this FVK run uses a mini-K model of the pure accessor, not full Python or Django rendering semantics. PO-002 discharges the source-level data-shape requirement by inspecting `Widget.get_context()` and `ChoiceWidget.create_option()`, and PO-007 keeps the proof status honest by recording commands without running them.

## Artifacts

Created:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-django-boundwidget.k`
- `fvk/boundwidget-spec.k`

No tests, Python, or K tooling were run, per the task instructions.
