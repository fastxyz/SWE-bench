# Baseline Notes

## Root cause

`Model.pk` is an alias for the model's `_meta.pk` field. In multi-table
inheritance, the child model's primary key is commonly a parent-link
`OneToOneField`, while the parent table's own primary-key attribute is also
present on the child instance. The old `Model._set_pk_val()` setter only wrote
the child `_meta.pk.attname`. After `obj.pk = None`, inherited parent primary
key attributes such as `id` or a custom parent PK remained populated, so
`save()` treated the parent row as existing and updated it instead of inserting
a copied parent row.

## Changed files

`repo/django/db/models/base.py`

Updated `Model._set_pk_val()` to assign the new value to every field in the
active primary-key parent-link chain. For a normal model this still sets only
the local PK. For a multi-table child, it sets the child parent-link column and
then follows `target_field` through parent-link primary keys until it reaches
the concrete parent PK. This keeps the values consulted by `_save_parents()`
and `_save_table()` in sync when `pk` is reset.

## Assumptions and alternatives

I assumed the intended behavior is that assigning `obj.pk = None` should reset
the same identity chain that `obj.pk` represents, including inherited parent
primary keys in multi-level concrete inheritance.

I rejected setting every entry in `self._meta.parents` to `None` because models
can have parent links that are not the model primary key, such as children with
their own explicit primary key. Resetting those links from the `pk` setter would
change non-PK relationships and could break models with multiple concrete
parents.

I also rejected changing save logic. The save path already inserts when the
primary-key values it receives are unset; the bug is that `pk` assignment left
stale inherited PK values behind before save was called.
