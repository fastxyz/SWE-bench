# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Model

The mini semantics in `fvk/mini-django-schema.k` abstracts the relevant
SQLite `add_field()` decision to:

```text
shouldRemake(field(NULL, HASDEFAULT, UNIQUE))
  = not NULL or HASDEFAULT or UNIQUE
```

This matches V1:

```python
if (
    not field.null or
    self.effective_default(field) is not None or
    field.unique
):
    self._remake_table(model, create_field=field)
else:
    super().add_field(model, field)
```

The abstraction keeps the bug-bearing property: whether a unique field can
reach the base add-column path.

## Proof Sketch

### PO-001 and PO-002

For `field(true, false, true)`:

```text
shouldRemake = not true or false or true
             = false or false or true
             = true
```

Only the `Remake` rule is enabled, so `addField(field(true, false, true))`
reaches `Remake`. The same simplification holds for
`field(NULL, HASDEFAULT, true)` because the final disjunct is true for every
`NULL` and `HASDEFAULT`.

This removes the pre-fix path where a unique field reached `BaseAdd` and caused
SQLite to see `ALTER TABLE ... ADD COLUMN ... UNIQUE`.

### PO-003

`OneToOneField.__init__()` sets `unique=True`, and `Field.unique` returns
`self._unique or self.primary_key`. Therefore the reported nullable
`OneToOneField` is an instance of PO-001 and PO-002.

### PO-004

For `field(false, HASDEFAULT, UNIQUE)`:

```text
shouldRemake = not false or HASDEFAULT or UNIQUE
             = true or HASDEFAULT or UNIQUE
             = true
```

For `field(NULL, true, UNIQUE)`:

```text
shouldRemake = not NULL or true or UNIQUE
             = true
```

Both existing remake classes remain remake classes.

### PO-005

For `field(true, false, false)`:

```text
shouldRemake = not true or false or false
             = false
```

The `Remake` rule is disabled and the `BaseAdd` rule is enabled. Thus the
supported nullable, no-default, non-unique fast path is preserved.

### PO-006

The proof does not require any signature or dispatch change. The branch result
is one of the same two implementation paths V1 inherited from the previous
SQLite schema editor.

## Machine-Check Commands Not Run

These commands are the future machine-check path. They were not executed in
this session.

```sh
kompile fvk/mini-django-schema.k --backend haskell
kast --backend haskell fvk/sqlite-add-field-spec.k
kprove fvk/sqlite-add-field-spec.k
```

Expected machine-check result after a valid K environment is available:
`kprove` returns `#Top` for the claims in `fvk/sqlite-add-field-spec.k`.

## Test Recommendation

Do not remove tests. Because the proof is not machine-checked and the project
tests were not run, all existing tests should be kept.

Recommended tests for a normal execution environment:

- SQLite migration/schema test adding `OneToOneField(null=True)` to an existing
  model.
- SQLite schema test adding a generic nullable `unique=True` field with no
  effective default.
- Regression check that a nullable, non-unique, no-default field still uses the
  ordinary add-column path where appropriate.
