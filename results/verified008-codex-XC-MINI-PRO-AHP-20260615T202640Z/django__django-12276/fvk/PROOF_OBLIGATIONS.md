# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Status |
| --- | --- | --- | --- |
| PO-1 | For `FileInput`, truthy initial data suppresses rendered `required` when field and form gates are true. | E1, E2, E4, E5; K claim `buildRequiredAttr(FileInput, initial, true, true) => false`. | Discharged by construction. |
| PO-2 | For `FileInput`, absence of initial data preserves rendered `required` when field and form gates are true. | E3; K claim `buildRequiredAttr(FileInput, noInitial, true, true) => true`. | Discharged by construction. |
| PO-3 | `field.required=False` prevents rendered `required` even for file widgets. | E7; K claim `buildRequiredAttr(FileInput, initial, false, true) => false`. | Discharged by construction. |
| PO-4 | `Form.use_required_attribute=False` prevents rendered `required` even for file widgets. | E7; K claim `buildRequiredAttr(FileInput, initial, true, false) => false`. | Discharged by construction. |
| PO-5 | `ClearableFileInput` inherits equivalent behavior after the override is removed. | E5, E6; K claims for `ClearableFileInput` initial and no-initial cases. | Discharged by construction. |
| PO-6 | The `not initial` predicate matches server-side preservation semantics for file fields. | E8; `FileField.clean()` returns `initial` when no data is submitted and initial is truthy. | Discharged by source inspection. |
| PO-7 | Public callsites and subclasses remain compatible. | E7, E9; compatibility audit; unchanged `use_required_attribute(initial)` signature. | Discharged by source inspection. |
| PO-8 | Public widget documentation names the owner of the special initial-file behavior. | E10; `docs/ref/forms/widgets.txt` updated to name `FileInput`. | Discharged by V2 documentation edit. |

## Proof Commands

These commands are emitted for later machine-checking only. They were not run.

```sh
cd fvk
kompile mini-django-fileinput.k --backend haskell
kast --backend haskell fileinput-required-spec.k
kprove fileinput-required-spec.k
```

Expected machine-check result after the toolchain is run: `#Top` for all claims.
