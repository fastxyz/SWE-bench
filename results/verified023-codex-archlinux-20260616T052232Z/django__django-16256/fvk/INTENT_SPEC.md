# Intent Spec

Status: constructed, not machine-checked.

## Intent-only obligations

I1. Async `acreate()`, `aget_or_create()`, and `aupdate_or_create()` on related
managers must be proper related-manager methods, not copied queryset proxy
methods.

Source: `benchmark/PROBLEM.md`: "acreate(), aget_or_create(), and
aupdate_or_create() doesn't work as intended on related managers" and "they
don't call create(), get_or_create(), and update_or_create() respectively from a
related manager but from the QuerySet."

I2. For reverse many-to-one managers, the async method must delegate to the
existing reverse related manager sync method, preserving its behavior of
checking the foreign key value, injecting the bound instance into the foreign
key, and selecting the write database with the instance hint.

Source: `repo/django/db/models/fields/related_descriptors.py` sync methods in
`create_reverse_many_to_one_manager()`; public tests in
`repo/tests/get_or_create/tests.py` state that related manager
`update_or_create()` should create/update through the relation.

I3. For many-to-many managers, the async method must delegate to the existing
many-to-many related manager sync method, preserving object linking through
`add()` and preserving the `through_defaults` argument for custom through
models.

Source: `repo/django/db/models/fields/related_descriptors.py` sync methods in
`create_forward_many_to_many_manager()`; public tests in
`repo/tests/m2m_through/tests.py` require `through_defaults` to populate
intermediate model fields for `create()`, `get_or_create()`, and
`update_or_create()`.

I4. Generic relation managers are in the same intended family: they are
relation-specific managers with sync `create()`, `get_or_create()`, and
`update_or_create()` methods that populate content type and object id fields.
Their async variants must also delegate to those sync methods rather than to a
queryset proxy.

Source: `repo/django/contrib/contenttypes/fields.py` defines
`GenericRelatedObjectManager`; public tests in
`repo/tests/generic_relations/tests.py` state that generic related manager
`get_or_create()` and `update_or_create()` should create/update through the
generic relation.

I5. Normal queryset and manager async behavior is out of scope for repair and
must remain unchanged. The fix should not change `BaseManager` proxy generation
globally.

Source: `repo/tests/async/test_async_queryset.py` covers normal queryset async
methods; the issue names related managers as the failing surface.

I6. The new async related-manager methods are data-mutating methods and should
carry `alters_data = True`, matching the synchronous related-manager methods
and the public issue hint for `acreate()`.

Source: existing sync related-manager methods set `alters_data = True`; the
problem hint shows `acreate.alters_data = True`.

## Domain

The domain is any constructed Django related manager instance of these families:
reverse many-to-one, many-to-many, or generic relation, and any call to
`acreate()`, `aget_or_create()`, or `aupdate_or_create()` with arguments valid
for the corresponding synchronous method. Existing sync method preconditions
are preserved rather than re-specified: for example unsaved related instances,
database integrity failures, router behavior, and validation errors should
continue to be determined by the sync method that is wrapped.

