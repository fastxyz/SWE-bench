# Formal Spec English

The K artifacts are `mini-schema.k` and `schema-editor-spec.k`. They are
constructed, not machine-checked.

## SPEC-C0: diagnostic baseline mechanism

If the deletion lookup for an `index_together` removal filters only on
`index=True`, and the database introspection list contains both:

- `_uniq`, same columns, `index=True`, `unique=True`; and
- `_idx`, same columns, `index=True`, `unique=False`;

then the selected name list has length 2 and `_delete_composed_index()` reaches
the wrong-count error path.

## SPEC-C1: V1 disambiguates when unique appears first

For the same two database objects, ordered as `_uniq` then `_idx`, the V1
`index_together` deletion lookup filters with `index=True` and `unique=False`.
It reaches `deleted("_idx")`, not the wrong-count error path.

## SPEC-C2: V1 disambiguates when index appears first

For the same two database objects, ordered as `_idx` then `_uniq`, the V1 lookup
again reaches `deleted("_idx")`. The proof does not rely on the unique object
being before or after the non-unique index.

## Frame and compatibility conditions

The formal claims do not alter `unique_together` deletion. The source frame
condition is that `alter_unique_together()` still calls `_delete_composed_index()`
with `{'unique': True}`. No method signature, return type, or public operation
shape changes.
