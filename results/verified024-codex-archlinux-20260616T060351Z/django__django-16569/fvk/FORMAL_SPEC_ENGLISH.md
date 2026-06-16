# Formal Spec English

This file paraphrases the nontrivial formal claims in
`formset-add-fields-spec.k`. The K artifacts are constructed, not
machine-checked.

## Modeled operation

`addFieldsDelete(canDelete, canDeleteExtra, index, initialCount)` models only
the deletion-field projection of `BaseFormSet.add_fields()`.

The modeled observable is whether `deleteField()` is inserted into the form's
field set and whether the operation leaves the exception cell as
`noException`.

## Claims

C1. If `canDelete` is false, no `DELETE` field is added for any in-domain
`index`, regardless of `canDeleteExtra`.

C2. If `canDelete` is true and `canDeleteExtra` is true, `DELETE` is added for
any in-domain `index`, including the empty-form index `None`.

C3. If `canDelete` is true, `canDeleteExtra` is false, and `index` is `None`,
no `DELETE` field is added and no exception occurs.

C4. If `canDelete` is true, `canDeleteExtra` is false, and `index` is an integer
less than `initialCount`, `DELETE` is added.

C5. If `canDelete` is true, `canDeleteExtra` is false, and `index` is an integer
greater than or equal to `initialCount`, no `DELETE` field is added.

C6. The proof domain requires `initialCount >= 0`. For integer indexes, the
proof domain requires `index >= 0`; `index=None` is admitted separately for
the empty template form.

C7. The modeled delete-field operation does not alter non-delete fields. The
source patch also does not alter `can_order` logic, method signatures, or
subclass dispatch.
