# Findings

Status: constructed, not machine-checked.

## F-001: V1 changed related-object validation through an objectless hook call

Classification: code bug in V1, fixed in V2.

Input / scenario:

```python
class ArticleAdmin(admin.ModelAdmin):
    inlines = [AuditInline]

    def get_inlines(self, request, obj=None):
        if obj is None:
            return []
        return [AuditInline]
```

Observed in V1: `to_field_allowed(request, to_field)` gathered inline models
from `admin.get_inlines(request)`, which passes no object and therefore sees
`[]` in this scenario. The inline model from `AuditInline` could be omitted from
the related-object validation registry.

Expected: The issue asks for dynamic inline display through
`get_inline_instances()`, and public docs identify static `inlines` as the
registry relevant to "Bad Request" related-object validation. This path should
continue to use `admin.inlines`.

Resolution: V2 reverted the `to_field_allowed()` change. See PO-004.

## F-002: Missing public tests for `get_inlines`

Classification: test gap, not addressed because test files are forbidden.

Input / scenario: a `ModelAdmin` subclass returns `[ConcertInline]` from
`get_inlines(request, band)` and `[]` from `get_inlines(request, None)`.

Observed: The source now supports this behavior, but no test file was modified
because the task forbids test edits.

Expected: A future public test should assert that `get_inline_instances()`
passes both `request` and `obj` to `get_inlines()` and preserves permission
filtering.

Resolution: No source change required beyond PO-001 through PO-003.

## F-003: System checks remain static

Classification: confirmed frame condition.

Input / scenario: a subclass returns a dynamically chosen inline class from
`get_inlines()` that is not listed in static `inlines`.

Observed: `ModelAdminChecks._check_inlines()` validates only static
`obj.inlines`.

Expected: This is acceptable because checks have no request or object context.
Dynamic hook results cannot be generally validated at check time.

Resolution: No source change. See PO-006.

## Proof-derived findings from `/verify`

No unresolved proof-derived code bug remains after F-001 was fixed. The proof
is constructed only; the emitted K commands were not run, so test removal is not
recommended.
