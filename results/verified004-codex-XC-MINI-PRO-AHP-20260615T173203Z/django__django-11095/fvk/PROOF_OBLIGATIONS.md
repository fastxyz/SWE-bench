# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Default hook returns static inlines

Source evidence: E-001, E-003, E-004.

Claim: `ModelAdmin.get_inlines(request, obj=None)` must return `self.inlines`
unless a subclass overrides it.

Discharge: V2 adds:

```python
def get_inlines(self, request, obj=None):
    """Hook for specifying custom inlines."""
    return self.inlines
```

## PO-002: Inline instance construction uses hook-selected classes

Source evidence: E-001, E-002, E-003.

Claim: `get_inline_instances(request, obj)` must iterate over
`self.get_inlines(request, obj)`, not `self.inlines`.

Discharge: V2 changes the loop source to:

```python
for inline_class in self.get_inlines(request, obj):
```

## PO-003: Permission and instance semantics are preserved

Source evidence: E-002.

Claim: After selecting inline classes, `get_inline_instances()` must preserve
the existing construction, permission skip, and `max_num = 0` behavior.

Discharge: V2 changes only the iterable expression. The body of the loop is
unchanged.

## PO-004: Related-object validation frame condition

Source evidence: E-005 and Finding F-001.

Claim: `to_field_allowed()` must continue to collect inline models from static
`admin.inlines`.

Discharge: V2 reverts V1's `admin.get_inlines(request)` call back to:

```python
for inline in admin.inlines:
```

## PO-005: Public signature compatibility

Source evidence: E-001 and compatibility audit.

Claim: Existing public method signatures must remain compatible:

- `get_inline_instances(self, request, obj=None)` unchanged.
- new hook signature is `get_inlines(self, request, obj=None)`.

Discharge: V2 satisfies both signatures.

## PO-006: Admin checks frame condition

Source evidence: E-006 and Finding F-003.

Claim: System checks remain based on static `inlines`.

Discharge: No change is made to `repo/django/contrib/admin/checks.py`.
