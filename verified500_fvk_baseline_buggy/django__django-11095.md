# django__django-11095

- **Verdict:** CONFIRMED baseline-buggy. Both baseline and FVK have
  `resolved: true` in the official eval reports, but baseline introduced a
  real admin validation regression in `BaseModelAdmin.to_field_allowed()`.
  FVK fixed that regression by keeping related-object validation on static
  `admin.inlines`.
- **Primary FVK finding:** `F-001: V1 changed related-object validation through
  an objectless hook call`.
- **Proof status:** constructed, not machine-checked. The FVK artifacts provide
  K claims and proof obligations, but the recorded run did not execute `kprove`.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue

The issue asks Django admin to expose a runtime hook for choosing inline
classes:

```python
def get_inlines(self, request, obj):
    ...
```

The intended behavior is additive and localized. `ModelAdmin.get_inline_instances()`
should call the hook with both `request` and `obj`, then keep the existing inline
instance construction and permission filtering. Existing static behavior should
remain the default when subclasses do not override the hook.

## What baseline did

Baseline implemented the requested hook and changed
`ModelAdmin.get_inline_instances()` to iterate over:

```python
self.get_inlines(request, obj)
```

That part is correct. The bug is that baseline also changed
`BaseModelAdmin.to_field_allowed()` from scanning static inline registrations:

```python
for inline in admin.inlines:
```

to calling the dynamic hook without an object:

```python
for inline in admin.get_inlines(request):
```

That call passes `obj=None` implicitly. `to_field_allowed()` is not part of the
inline display construction path; it participates in related-object validation
for public admin raw-id / `to_field` flows.

## Why baseline is buggy

The dynamic hook can legitimately depend on the object being edited:

```python
class ArticleAdmin(admin.ModelAdmin):
    inlines = [AuditInline]

    def get_inlines(self, request, obj=None):
        if obj is None:
            return []
        return [AuditInline]
```

Under baseline, `to_field_allowed(request, to_field)` calls
`admin.get_inlines(request)` with no object. In this scenario the hook returns
`[]`, so the inline model from `AuditInline` can be omitted from the registered
related-object model set. A valid related-object path can then be rejected even
though the static admin registration still includes the inline.

This is a real bug because the object-dependent display hook has been allowed
to mutate a separate static validation registry. The absence of an object in
`to_field_allowed()` is not an accidental omission; that path has no edited
object context to pass.

## What FVK changed and why

FVK kept the two correct parts:

- add `ModelAdmin.get_inlines(request, obj=None)`;
- make `get_inline_instances(request, obj)` delegate to that hook.

FVK removed the baseline-only change in `to_field_allowed()` and restored the
static scan:

```python
for inline in admin.inlines:
```

The FVK formal argument is the `TO-FIELD-ALLOWED-FRAME` claim in
`FORMAL_SPEC_ENGLISH.md`: the related-object validation registry remains based
on static `admin.inlines`; it is not affected by the new dynamic hook.

That frame condition separates two public obligations:

- inline rendering is dynamic and request/object aware;
- related-object validation remains static because it has no object context.

## FVK Formal Argument

- **FVK status:** constructed, not machine-checked.
- **FVK formal argument:** PO-004/PO-006 / `TO-FIELD-ALLOWED-FRAME`: related-object validation and admin checks are static registration obligations; they must inspect `admin.inlines`, not objectless dynamic hook results.
- **Why it catches baseline:** baseline calls `get_inlines(request)` from `to_field_allowed()` without an object, allowing object-dependent display logic to mutate the validation registry.

## Concrete demonstration

The failure does not require exotic code. Any hook that returns no inlines for
the add view or objectless state can trigger it:

```python
def get_inlines(self, request, obj=None):
    return [AuditInline] if obj is not None else []
```

When admin validation asks whether a `to_field` relation is allowed, baseline
observes the objectless result and drops `AuditInline.model` from the model set
used by validation. FVK observes the static `admin.inlines` list, so
`AuditInline.model` remains available for validation.

## Why the tests missed it

The official FAIL_TO_PASS test checks the requested display hook:

```text
test_get_inline_instances_override_get_inlines
```

That test exercises `get_inline_instances()`. It does not combine an
object-dependent `get_inlines()` override with the unrelated
`to_field_allowed()` validation path. Both baseline and FVK therefore pass the
official tests, even though baseline has a validation regression.

## FVK vs. Human Fix

**Human fix issue:** no.

Gold adds the dynamic inline hook only to inline instance construction. It does not route `to_field_allowed()` through an objectless dynamic hook. FVK restores that same static validation boundary after baseline crossed it.


The official gold patch adds `get_inlines()` and changes
`get_inline_instances()` to call it. It does not modify `to_field_allowed()`.
That matches the FVK boundary: the display hook is dynamic, but
related-object validation stays on static inline registration.

FVK is therefore not merely a stylistic alternative. It removed a baseline-only
behavioral regression that the official fix never introduced.


## Confidence and caveats

Confidence is high. The baseline/FVK patch diff is small and isolates the
defect to one baseline-only edit. The official gold patch independently
confirms that `to_field_allowed()` should not have been changed.

The proof artifacts are constructed rather than machine-checked, so they should
be cited as formal proof-structured evidence, not as a completed `kprove`
machine-check.
