# ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

Do not make a V2 source edit. The FVK audit found that the V1 guard is exactly
the intent-derived condition:

```python
not cls._meta.abstract and (self.width_field or self.height_field)
```

This discharges PO1 through PO8 and resolves F1 without creating the regressions
checked by F2 through F5.

## What to Keep

- Keep the V1 source change in `repo/django/db/models/fields/files.py`.
- Keep the existing `update_dimension_fields()` early return. It remains useful
  for direct calls, deferred fields, and defensive consistency.
- Keep the existing `ImageFileDescriptor.__set__()` behavior unchanged.
- Keep tests in place. The proof was not machine-checked and tests were not run.

## Future Test Ideas

These are recommendations only; this benchmark forbids test edits.

- Assert that a concrete no-dimension `ImageField` does not add an
  `update_dimension_fields` receiver to `post_init`.
- Assert that width-only, height-only, and both-dimension `ImageField`
  declarations still add the receiver.
- Assert that a dimension-bearing field inherited from an abstract model still
  has post-init dimension maintenance on the concrete subclass.
- Assert that assigning an image after initialization still refreshes dimension
  fields.

## Open Risks

- The proof is constructed, not machine-checked.
- Performance improvement magnitude is not proved here; the proof only covers
  the receiver-registration predicate and behavior preservation.
- No hidden tests, external benchmark data, or upstream fix knowledge were used.
