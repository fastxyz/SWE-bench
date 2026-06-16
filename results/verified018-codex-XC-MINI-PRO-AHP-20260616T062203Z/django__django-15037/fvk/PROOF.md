# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K commands were
run.

## Theorem

For every single-column foreign key relation visible to `inspectdb`, if backend
introspection reports the relation target as `(rel_column, rel_table)`, the
generated relation field targets the same database column:

- if `rel_column` is the target table primary key, Django's default relation
  target is sufficient and `to_field` is omitted;
- otherwise, `to_field` is emitted with the target model field name generated for
  `rel_column`.

## Proof of O1: Non-PK Target Preservation

Assume `column_name in relations` and
`relations[column_name] == (rel_column, rel_table)`.

In the relation branch, V1 binds:

```python
rel_column, rel_table = relations[column_name]
```

It then evaluates:

```python
if rel_column != get_primary_key_column(rel_table):
```

Under O1's precondition, this condition is true. The branch computes:

```python
rel_to_field = get_column_to_field_name(rel_table).get(rel_column, rel_column)
extra_params['to_field'] = rel_to_field
```

By O3, `rel_to_field` is the generated target model field name for
`rel_column`, with a fallback to the raw column only when no mapping is present.
The final field-description assembly appends all `extra_params`, so the emitted
relation contains `to_field=rel_to_field`.

Therefore the generated relation preserves a non-primary-key target column.

## Proof of O2: Primary-Key Target Frame

Assume `rel_column == get_primary_key_column(rel_table)`.

The same branch condition:

```python
if rel_column != get_primary_key_column(rel_table):
```

is false, so V1 does not add `extra_params['to_field']`. Django's documented
default is to target the related object's primary key, so omitting `to_field`
preserves the correct semantics for primary-key references, including primary
keys whose column name is not `id`.

## Proof of O3: Target Field-Name Soundness

`normalize_table_columns()` iterates over the same `table_description` order as
the normal model-generation loop. On each row it calls:

```python
self.normalize_col_name(column_name, used_column_names, column_name in relations)
```

The normal field-generation loop calls:

```python
self.normalize_col_name(column_name, used_column_names, is_relation)
```

where `is_relation == column_name in relations`. Both loops start with an empty
`used_column_names` list and append exactly the returned `att_name` after each
row. By induction over rows, before every row both loops have the same
`used_column_names`, call `normalize_col_name()` with the same arguments, and
therefore compute the same `att_name`. The mapping stored by
`normalize_table_columns()` is exactly the field name the generation loop would
use for that column.

This discharges the concern that `to_field` must be a model field name rather
than the raw database column.

## Proof of O4: Relation Output Frame

V1 adds only one possible key to `extra_params`: `to_field`, and only in the
non-primary-key target branch. It does not alter:

- the earlier `primary_key`/`unique` calculation;
- the `ForeignKey` vs. `OneToOneField` selection;
- `rel_to` calculation for self-relations and forward references;
- `models.DO_NOTHING` insertion;
- null/blank insertion;
- non-relation field type generation.

Thus all unrelated generated-output behavior is framed.

## Proof of O5: Public Compatibility

The patch adds one internal method on the management command class and two local
caches inside `handle_inspection()`. It does not change command-line arguments,
backend method signatures, backend return shapes, model field APIs, or tests.

## Adequacy Result

The constructed proof matches the public intent:

- The issue's concrete `foo(other_id)` example is covered by O1.
- The hint's "non pk field" family is covered by O1 for arbitrary
  `rel_column != target_pk`.
- Django's primary-key default is covered by O2 so the fix does not overreach.
- Django's requirement that `to_field` names a model field is covered by O3.

No FVK finding requires a V2 code change. V1 stands unchanged.

## Test Guidance

No test files were changed. Because the proof was not machine-checked and tests
were not run, no existing tests are recommended for removal.

Useful tests to add outside this benchmark's fixed-test constraint:

- `inspectdb` emits `to_field='other_id'` for the issue schema.
- `inspectdb` omits `to_field` when the referenced column is the target primary
  key even if the primary-key column is not named `id`.
- `inspectdb` emits a normalized target field name when the referenced target
  column would be renamed by `normalize_col_name()`.
