# FVK Spec: `ModelAdminChecks._check_list_display_item()`

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for
`repo/django/contrib/admin/checks.py::ModelAdminChecks._check_list_display_item()`
and its direct caller `_check_list_display()`. The target has no loops, so the
proof obligations are complete branch/case obligations rather than loop
circularities.

The observable under specification is the returned check list for one
`list_display` item:

- `OK`: `[]`
- `E108`: a single `checks.Error(..., id='admin.E108')`
- `E109`: a single `checks.Error(..., id='admin.E109')`

The formal model abstracts Django/Python object machinery into the lookup
outcomes that the helper actually branches on:

- `callable(item)`
- `obj.model._meta.get_field(item)` resolves or raises `FieldDoesNotExist`
- `hasattr(obj, item)` succeeds for `ModelAdmin` attributes
- `getattr(obj.model, item)` resolves or raises `AttributeError`
- the resolved value is or is not a `models.ManyToManyField`

This abstraction is property-complete for the issue because it distinguishes the
failing pre-V1 case (`get_field` succeeds while model class attribute access
fails), the missing-field case, the `ManyToManyField` case, and the documented
field-before-admin-attribute precedence case.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "`admin.E108` is raised on fields accessible only via instance" | A model field found through `_meta.get_field()` must be valid even when model class attribute access/`hasattr(model, item)` fails. | Encoded by PO2 and claim `FIELD_REGULAR_OK`. |
| E2 | problem | "`only return an E108 in the case both of them fail`" | `admin.E108` is emitted only when field metadata lookup, `ModelAdmin` lookup, and model attribute lookup all fail. | Encoded by PO7 and claim `MISSING_ALL_E108`. |
| E3 | problem | "`If either of those means ... are successful then we need to check if it's a ManyToMany.`" | After any successful field/model-attribute resolution, `ManyToManyField` produces `admin.E109`. | Encoded by PO3 and PO6. |
| E4 | docs | "`There are four types of values that can be used in list_display`" followed by model fields, callables, `ModelAdmin` methods, and model attributes/methods. | These four item categories are accepted unless another rule forbids them. | Encoded by PO1, PO2, PO4, PO5. |
| E5 | docs | "`ManyToManyField` fields aren't supported" | A resolved `ManyToManyField` is rejected with `admin.E109`. | Encoded by PO3 and PO6. |
| E6 | docs | "Django will try to interpret every element of `list_display` in this order: A field of the model. A callable. A string representing a `ModelAdmin` attribute. A string representing a model attribute." | Validation should not let a same-named `ModelAdmin` attribute override a model field; a model field wins for validation, including `ManyToManyField` rejection. | Encoded by PO3 and the V2 source edit. |
| E7 | public tests | Existing checks assert missing fields produce `admin.E108`, `ManyToManyField` fields produce `admin.E109`, and field/admin/model/callable valid cases pass. | Preserve existing user-visible error IDs and successful categories. | Encoded by PO1, PO2, PO3, PO4, PO7. |
| E8 | implementation | `lookup_field()` tries `_get_non_gfk_field()` before callable/admin/model attribute fallback. | The validation order should be compatible with runtime resolution's model-field-first behavior. | Supports E6; encoded by PO3. |

## Contract

For every documented `list_display` item in this audit domain:

1. If `item` is callable, `_check_list_display_item()` returns `OK`.
2. Otherwise, model metadata lookup is attempted before admin/model attribute
   fallback.
3. If metadata lookup resolves a non-`ManyToManyField` field, the result is
   `OK`, even if accessing the field on the model class would fail.
4. If metadata lookup resolves a `ManyToManyField`, the result is `E109`,
   including when a same-named `ModelAdmin` attribute exists.
5. If metadata lookup raises `FieldDoesNotExist` and `obj` has the named
   attribute, the result is `OK`.
6. If metadata lookup raises `FieldDoesNotExist`, `obj` lacks the named
   attribute, and `getattr(obj.model, item)` resolves a non-`ManyToManyField`
   object, including `None`, the result is `OK`.
7. If the model attribute fallback resolves a `ManyToManyField`, the result is
   `E109`.
8. If metadata lookup raises `FieldDoesNotExist`, `obj` lacks the named
   attribute, and model attribute fallback raises `AttributeError`, the result
   is `E108`.

## Formal Artifacts

- `fvk/mini-admin-check.k`: mini semantics for the abstract decision procedure.
- `fvk/list-display-check-spec.k`: K claims corresponding to the obligations
  above.
- Exact commands, not executed:

```sh
cd fvk
kompile mini-admin-check.k --backend haskell
kast --backend haskell list-display-check-spec.k
kprove list-display-check-spec.k
```

