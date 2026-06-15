# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbol: `ModelAdmin.get_inlines`

Compatibility status: additive public hook.

No in-repo overrides of `get_inlines` existed in the allowed source tree before
the V1 patch. Adding the method is the requested public API extension.

Residual compatibility risk: third-party `ModelAdmin` subclasses could already
define a method named `get_inlines` with an incompatible signature. This is a
general risk of adding a new hook, but it is directly required by public intent
E-001.

## Changed dispatch: `ModelAdmin.get_inline_instances`

Compatibility status: compatible.

Existing callers still call `get_inline_instances(request, obj=None)` with the
same signature and receive inline instances. Existing subclasses overriding
`get_inline_instances()` are unaffected because overriding the method bypasses
the new default implementation.

## V1 changed dispatch: `BaseModelAdmin.to_field_allowed`

Compatibility status: rejected and reverted in V2.

V1 called `admin.get_inlines(request)` while building the related-object
validation registry. That introduced a new virtual dispatch with no `obj`
context. Because the public issue requires object-dependent inline selection,
calling the hook with `obj=None` in this path can omit classes that are present
for change objects. V2 restores the previous static `admin.inlines` lookup.

## Admin checks

Compatibility status: unchanged.

`django.contrib.admin.checks.ModelAdminChecks._check_inlines()` continues to
validate the static `inlines` attribute. No request/object context is available
there, and no public evidence requires changing checks.
