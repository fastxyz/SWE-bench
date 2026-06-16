# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Pre-fix reconstructed id ignored the rendered option id

Classification: code bug, fixed by V1.

Evidence: prompt entries E1 through E3 in `fvk/SPEC.md`.

Concrete input:

- widget type: `CheckboxSelectMultiple`
- field html name: `composers`
- form `auto_id`: `"%s_id"`
- option index: `0`
- subwidget data after `ChoiceWidget.create_option()`: `attrs["id"] == "composers_id_0"`

Observed before V1: `BoundWidget.id_for_label` reconstructed `"id_composers_0"` from name and index.

Expected: `"composers_id_0"`, the id already stored in `self.data["attrs"]["id"]`.

Resolution: V1 returns `self.data["attrs"].get("id", "")`, so the present-id case now returns the rendered option id.

Related proof obligations: PO-001, PO-002, PO-003.

## F-002: Existing select-option expectation is suspect legacy behavior

Classification: suspect public-test conflict, intentionally not preserved.

Evidence: `repo/tests/forms_tests/tests/test_forms.py` has `test_iterable_boundfield_select`, where `fields[0].tag()` renders `<option value="john">John</option>` with no id, but the test expects `fields[0].id_for_label == "id_name_0"`.

Concrete input:

- widget type: default `Select`
- form `auto_id`: `False`
- option index: `0`
- rendered option attrs: no `"id"` key

Observed before V1: `BoundWidget.id_for_label == "id_name_0"` even though the option has no rendered id.

Expected under the intent spec: `""`, because there is no element id to output.

Resolution: V1 returns `""` for missing `"id"`. This may require updating that public test in a normal Django workflow, but the task forbids modifying tests.

Related proof obligations: PO-004, PO-006.

## F-003: Full Django rendering semantics are not machine-checked here

Classification: proof capability gap, not a code bug.

Evidence: FVK uses a mini-K fragment for this audit, not full Python or full Django template semantics.

Scope of constructed proof: the pure accessor behavior for `BoundWidget.id_for_label` over a subwidget attrs map, plus source-level reasoning that Django's subwidget producers provide that map.

Residual risk: a future machine check would still rely on the adequacy of the mini semantics and the source-level producer contract. This is acceptable for the current artifact-only task but remains a trusted base.

Related proof obligations: PO-002, PO-007.

## Proof-derived findings from `/verify`

No new production-code bug was found beyond F-001, which V1 already fixes.

The main proof-derived audit point is F-002: preserving the old fallback would be necessary only to satisfy a legacy test that expects a non-rendered id. The adequacy audit rejects that fallback because it would reintroduce invented ids and contradict the public issue's stated source of truth, `self.data["attrs"]["id"]`.

No source edit beyond V1 is justified.
