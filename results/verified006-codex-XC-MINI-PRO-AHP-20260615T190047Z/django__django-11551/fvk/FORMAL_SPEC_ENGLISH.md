# Formal Spec English

This is the English paraphrase of `list-display-check-spec.k`.

1. `CALLABLE_OK`: if the item is callable, the check returns `OK` regardless of
   metadata, admin attribute, or model attribute lookup outcomes.
2. `FIELD_REGULAR_OK`: if the item is not callable and model metadata lookup
   resolves a non-`ManyToManyField` value, the check returns `OK`.
3. `FIELD_NONE_OK`: if the item is not callable and the resolved value is
   `None`-like but not a `ManyToManyField`, the check returns `OK`.
4. `FIELD_M2M_E109`: if the item is not callable and model metadata lookup
   resolves a `ManyToManyField`, the check returns `E109`.
5. `FIELD_M2M_ADMIN_PRECEDENCE_E109`: if the item is not callable, model
   metadata lookup resolves a `ManyToManyField`, and a same-named
   `ModelAdmin` attribute exists, the check still returns `E109`.
6. `ADMIN_ATTR_OK`: if metadata lookup is missing and a `ModelAdmin` attribute
   exists, the check returns `OK`.
7. `MODEL_ATTR_REGULAR_OK`: if metadata lookup is missing, no `ModelAdmin`
   attribute exists, and model attribute fallback resolves a non-`ManyToManyField`
   value, the check returns `OK`.
8. `MODEL_ATTR_NONE_OK`: if metadata lookup is missing, no `ModelAdmin`
   attribute exists, and model attribute fallback resolves `None`, the check
   returns `OK`.
9. `MODEL_ATTR_M2M_E109`: if metadata lookup is missing, no `ModelAdmin`
   attribute exists, and model attribute fallback resolves a `ManyToManyField`,
   the check returns `E109`.
10. `MISSING_ALL_E108`: if metadata lookup is missing, no `ModelAdmin`
    attribute exists, and model attribute fallback is missing, the check
    returns `E108`.

