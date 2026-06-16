# PUBLIC_EVIDENCE_LEDGER.md

Status: public evidence only.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "When no callback is provided the class uses no callback instead of the formfield_callback of the base form provided." | Factory default `None` must not mask a base form `Meta` callback. |
| E2 | `benchmark/PROBLEM.md` | "FactoryForm uses the formfield_callback specified in the Meta attribute of MyForm" | `Meta.formfield_callback` must participate in model field generation. |
| E3 | `benchmark/PROBLEM.md` hints | "support it for consistency with other Meta options" | Resolve the callback through `ModelFormOptions` / resolved `Meta`, not a separate inheritance rule. |
| E4 | `repo/docs/topics/forms/modelforms.txt` | "Normal Python name resolution rules apply. ... the child's Meta, if it exists, otherwise the Meta of the first parent" | Child `Meta` replacement should block base `Meta` callback inheritance unless it explicitly inherits or defines it. |
| E5 | `repo/tests/model_forms/tests.py` | `test_custom_callback` and `test_bad_callback` exercise explicit factory callbacks. | Explicit factory callback still overrides; invalid callbacks still reach validation. |
| E6 | Python default-domain assumption | Object truthiness is distinct from identity with `None`. | Use `is not None`, not truthiness, for explicit factory callback detection. |
| E7 | `repo/django/forms/models.py` public signatures | `modelform_factory`, `modelformset_factory`, and `inlineformset_factory` accept `formfield_callback=None`. | Preserve signatures and delegate behavior through the existing factory path. |
