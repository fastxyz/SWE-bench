# Formal Specification in English

The K claims in `model-pk-spec.k` model a Django instance as:

- an attribute map from field attnames to values;
- a finite field graph where each primary-key parent link points to its target
  parent primary-key field, and a non-parent primary key has no successor;
- the operation `setPk(F, V)`, which corresponds to `Model._set_pk_val()` with
  `F = self._meta.pk` and `V` equal to the assigned value.

## Claim SET-PK-CHAIN

For every finite acyclic primary-key parent-link chain starting at field `F`,
executing `setPk(F, V)` terminates with every attname in that chain set to `V`.
Fields outside the chain keep their previous values.

## Claim SAVE-CONSEQUENCE

If `V` is `None` and `setPk(self._meta.pk, None)` has completed, then every
parent table whose primary key is represented by the chain has a `None`
primary-key value when Django's parent save logic reaches `_save_table()`.
Under ordinary `save()` without `force_update` or `update_fields`, `_save_table()`
therefore cannot update the old row on those tables and proceeds through the
insert path.

## Frame and compatibility condition

If `self._meta.pk` is not a parent link, the chain contains only that field, so
the setter is equivalent to the preexisting single-attribute assignment. Parent
links that are not in the active primary-key chain are not modified by the
setter.
