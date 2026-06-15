# Intent Spec

Status: constructed from public intent, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-11095`, limited to the
public admin API behavior changed by the patch:

- `ModelAdmin.get_inlines(request, obj=None)`.
- `ModelAdmin.get_inline_instances(request, obj=None)`.
- The V1-adjacent frame condition for `BaseModelAdmin.to_field_allowed()`.

It does not claim to verify all of Django admin.

## Required Behaviors

I-001: Django must expose a `ModelAdmin.get_inlines(request, obj=None)` hook.

Evidence: `benchmark/PROBLEM.md` says "add ModelAdmin.get_inlines() hook to
allow set inlines based on the request or model instance."

I-002: The hook must select inline classes, not already-created inline admin
instances.

Evidence: `benchmark/PROBLEM.md` says "What I want to do is just set
self.inlines to dynamic values according to different person or object. not
inline instances."

I-003: The default hook behavior must preserve existing static `inlines`
behavior.

Evidence: existing `ModelAdmin.inlines = []` and
`get_inline_instances()` previously iterated `self.inlines` directly.

I-004: `get_inline_instances(request, obj)` must use the selected inline
classes while preserving the existing instantiation, permission filtering, and
`max_num = 0` behavior.

Evidence: `benchmark/PROBLEM.md` describes the problem as users needing to copy
the `get_inline_instances()` for-loop only to vary the inline list.

I-005: Existing related-object validation behavior should not be changed by the
new hook unless required by the issue.

Evidence: public docs for `get_inline_instances()` warn that returned inlines
should be instances of classes defined in `inlines` to avoid a "Bad Request"
when adding related objects. This identifies `inlines` as the static registry
for that validation path.

I-006: System checks may remain based on the static `inlines` attribute.

Evidence: admin checks run without a request or model instance, while the new
hook is explicitly request/object dependent.
