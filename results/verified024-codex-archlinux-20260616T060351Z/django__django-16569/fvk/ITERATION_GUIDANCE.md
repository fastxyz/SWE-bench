# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No V2 source edit is justified by the FVK pass.

The FVK findings and proof obligations support the existing V1 edit:

- F1 plus PO2/PO3c show the reported empty-form failure is fixed.
- F2 plus PO3d/PO3e show indexed initial and extra form behavior is preserved.
- F3 plus PO4/PO5 show no public compatibility change is needed.
- F4 plus PO1 explains why nonstandard manual indexes were not expanded into
  this repair.

## Recommended follow-up tests

Do not modify tests in this task. For a normal Django development branch, add a
regression test covering:

```text
formset_factory(form=MyForm, can_delete=True, can_delete_extra=False)
FormSet(initial=None).empty_form
```

Expected: construction does not raise and the empty form does not include
`DELETE`.

## Machine-check follow-up

Run the recorded commands only in an environment with K installed. Run them
from `fvk/`:

```sh
kompile mini-python-formset.k --main-module MINI-PYTHON-FORMSET --syntax-module MINI-PYTHON-FORMSET-SYNTAX --backend haskell
kast --backend haskell formset-add-fields-spec.k
kprove formset-add-fields-spec.k --spec-module FORMSET-ADD-FIELDS-SPEC
```

Until then, treat the proof as constructed, not machine-checked, and do not
delete tests based on it.
