# Intent Specification

Status: constructed from public evidence, before accepting V1 behavior as the
specification. No tests or project code were executed.

## Scope

The audited unit is the deletion-field behavior of
`django.forms.formsets.BaseFormSet.add_fields(form, index)` as reached by
`BaseFormSet.empty_form` and by normal indexed form construction.

The full Django form rendering stack is outside this formal core. It is treated
as a trusted caller/provider of `form`, `form.fields`, `initial_form_count()`,
and the field constructor APIs. The proof target is the boolean decision to add
the `DELETE` field and the absence of the reported `None` comparison error.

## Intent-only obligations

I1. `empty_form` is a public formset attribute for dynamic forms. It must return
a form instance rather than fail while adding formset-managed fields.

I2. The empty template form is represented by `index is None`; this convention
must remain available to formset hooks.

I3. With `can_delete=True` and `can_delete_extra=False`, extra forms must not
get the option to delete. The empty template form is the template for extra
forms, so it must not get `DELETE` in that configuration.

I4. With `can_delete=True` and `can_delete_extra=False`, initial forms still
must get `DELETE` so existing objects can be deleted.

I5. With `can_delete=True` and `can_delete_extra=True`, delete fields remain
enabled for extra forms. The empty template form must keep `DELETE` because it
is used to create extra forms dynamically.

I6. With `can_delete=False`, `add_fields()` must not add a `DELETE` field.

I7. The change must not alter the public `add_fields(form, index)` signature,
the meaning of `index=None`, ordering-field behavior, or subclass override
dispatch through `super().add_fields(form, index)`.

I8. Default-domain assumption: outside `empty_form`, `index` is a nonnegative
integer form index. Manual calls with negative or non-integer, non-`None`
indices are not specified by the public evidence audited here.
