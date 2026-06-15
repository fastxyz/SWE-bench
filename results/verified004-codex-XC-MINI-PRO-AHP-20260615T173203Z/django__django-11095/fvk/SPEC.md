# FVK Spec

Status: constructed, not machine-checked.

## Scope

This specification audits the V1/V2 patch for `django__django-11095`. The
verified units are:

- `ModelAdmin.get_inlines(request, obj=None)`.
- `ModelAdmin.get_inline_instances(request, obj=None)`, including its inline
  class loop.
- The frame condition that `BaseModelAdmin.to_field_allowed()` continues to use
  static `admin.inlines` for related-object validation.

The full Django admin is out of scope for this FVK pass.

## Public Intent Ledger

E-001: The issue asks for `ModelAdmin.get_inlines()` with request and optional
object context. Obligation: provide a method with that signature.

E-002: The issue says overriding `get_inline_instances()` requires copying a
for-loop. Obligation: `get_inline_instances()` must delegate the inline class
selection to the new hook and keep the loop behavior.

E-003: The issue distinguishes dynamic inline classes from inline instances.
Obligation: `get_inlines()` returns inline classes; `get_inline_instances()`
continues to instantiate them.

E-004: Existing source iterated `self.inlines` directly. Obligation: default
`get_inlines()` returns `self.inlines` to preserve behavior.

E-005: Public docs warn that related-object "Bad Request" validation depends on
classes defined in `inlines`. Obligation: do not move `to_field_allowed()` to an
objectless dynamic hook call.

E-006: Existing admin checks validate `obj.inlines` without a request or object.
Obligation: leave system checks static unless independent public evidence
requires dynamic validation.

## Formal Contract

C-001: For any `ModelAdmin` instance `ma`, request `r`, and object `o`, the
default `ma.get_inlines(r, o)` returns the current value of `ma.inlines`.

C-002: `ma.get_inline_instances(r, o)` obtains the sequence of inline classes by
calling `ma.get_inlines(r, o)`.

C-003: For every inline class returned by `get_inlines(r, o)`,
`get_inline_instances(r, o)` constructs `inline_class(ma.model, ma.admin_site)`.
It then applies the same permission filtering used before the patch:

- if there is no request, append the instance;
- if there is a request and none of view/change, add, or delete permission is
  available, skip the instance;
- if there is a request and add permission is unavailable, set `max_num = 0`;
- otherwise append the instance.

C-004: `to_field_allowed(request, to_field)` still gathers inline models from
`admin.inlines`, not from `admin.get_inlines(request, obj=None)`.

C-005: Admin system checks remain based on static `obj.inlines`.

## Formal Files

The constructed K artifacts are:

- `fvk/mini-django-admin.k`.
- `fvk/modeladmin-inlines-spec.k`.

Commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-django-admin.k --backend haskell
kast --backend haskell fvk/modeladmin-inlines-spec.k
kprove fvk/modeladmin-inlines-spec.k
```
