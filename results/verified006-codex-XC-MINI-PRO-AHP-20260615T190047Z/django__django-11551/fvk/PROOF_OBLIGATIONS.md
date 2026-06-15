# FVK Proof Obligations

Status: constructed, not machine-checked.

## Branch Obligations

PO1. Callable acceptance: for any metadata/admin/model lookup outcomes,
`callable(item) == true` implies `OK`.

Evidence: SPEC ledger E4.

PO2. Metadata field acceptance: if `callable(item) == false` and
`obj.model._meta.get_field(item)` resolves a non-`ManyToManyField`, the result
is `OK` regardless of whether class attribute access would have failed.

Evidence: SPEC ledger E1, E2, E4.

PO3. Metadata `ManyToManyField` rejection and precedence: if
`callable(item) == false` and metadata lookup resolves a `ManyToManyField`, the
result is `E109`, even when a same-named `ModelAdmin` attribute exists.

Evidence: SPEC ledger E5, E6, E8.

PO4. `ModelAdmin` attribute acceptance after missing metadata: if metadata lookup
raises `FieldDoesNotExist` and `hasattr(obj, item)` is true, the result is `OK`.

Evidence: SPEC ledger E4, E7.

PO5. Model attribute fallback acceptance: if metadata lookup raises
`FieldDoesNotExist`, `hasattr(obj, item)` is false, and `getattr(obj.model,
item)` resolves a non-`ManyToManyField` object, including `None`, the result is
`OK`.

Evidence: SPEC ledger E2, E4 and the issue discussion of descriptors returning
`None`.

PO6. Model attribute fallback `ManyToManyField` rejection: if metadata lookup
raises `FieldDoesNotExist`, `hasattr(obj, item)` is false, and
`getattr(obj.model, item)` resolves a `ManyToManyField`, the result is `E109`.

Evidence: SPEC ledger E3, E5.

PO7. Missing item error: if metadata lookup raises `FieldDoesNotExist`,
`hasattr(obj, item)` is false, and `getattr(obj.model, item)` raises
`AttributeError`, the result is `E108`.

Evidence: SPEC ledger E2, E7.

PO8. Error shape preservation: `E108` and `E109` retain the pre-existing error
IDs and message families used by Django's admin checks.

Evidence: SPEC ledger E7.

PO9. Public compatibility: the helper signature, direct caller protocol, and
`_check_list_display()` indexing behavior are unchanged.

Evidence: PUBLIC_COMPATIBILITY_AUDIT.md.

## Non-Obligations

This pass does not prove total correctness separately from branch termination:
the target contains no loops or recursion and all modeled branches return.

This pass does not modify or prove behavior for undocumented, non-callable,
non-string `list_display` items. The public contract audited here is the
documented item family: callables and string names for model fields,
`ModelAdmin` attributes, and model attributes/methods.

