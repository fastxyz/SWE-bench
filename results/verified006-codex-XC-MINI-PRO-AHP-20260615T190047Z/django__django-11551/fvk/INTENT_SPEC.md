# Intent Spec

This file records intent before accepting candidate behavior.

1. `list_display` accepts four documented item categories: model field names,
   callables, string names for `ModelAdmin` attributes/methods, and string names
   for model attributes/methods.
2. A model field found through `_meta.get_field(item)` is a valid
   `list_display` item unless it is a `ManyToManyField`.
3. A valid model field must not be rejected merely because accessing the field
   through the model class descriptor raises `AttributeError`.
4. `admin.E108` is reserved for a `list_display` item that cannot be resolved as
   a callable, `ModelAdmin` attribute, model field, or model attribute/method.
5. A resolved `ManyToManyField` must be rejected with `admin.E109`.
6. Model fields have precedence over same-named `ModelAdmin` attributes for
   interpretation and validation.
7. Existing public error IDs and messages for `admin.E108` and `admin.E109`
   remain stable.

