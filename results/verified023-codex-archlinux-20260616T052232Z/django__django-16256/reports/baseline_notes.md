# Baseline Notes

## Root cause

`BaseManager._get_queryset_methods()` copies public `QuerySet` methods onto
manager classes as proxy methods that call `self.get_queryset()`. The async
`acreate()`, `aget_or_create()`, and `aupdate_or_create()` methods added to
`QuerySet` were therefore available on related managers even when those
managers did not define local async overrides.

For related managers this is incorrect because the synchronous `create()`,
`get_or_create()`, and `update_or_create()` implementations add relation
specific behavior before delegating to the base manager/queryset. Reverse
foreign key managers inject the parent instance into the foreign key value.
Many-to-many managers add newly created objects to the through table and honor
`through_defaults`. Generic relation managers inject the content type and object
id fields. The copied async queryset proxy bypassed those related-manager
methods by operating on `self.get_queryset()` instead.

## Changed files

`repo/django/db/models/fields/related_descriptors.py`

- Imported `sync_to_async`, matching the async queryset/model wrapper pattern
  already used elsewhere in Django.
- Added `acreate()`, `aget_or_create()`, and `aupdate_or_create()` to the
  reverse many-to-one related manager so async calls delegate to the related
  manager's existing synchronous methods and preserve foreign key injection.
- Added the same async methods to the many-to-many related manager, preserving
  the existing `through_defaults` keyword-only argument and ensuring created
  objects are linked through `add()`.
- Marked the new async methods with `alters_data = True`, matching the
  mutating nature of their synchronous counterparts.

`repo/django/contrib/contenttypes/fields.py`

- Imported `sync_to_async`.
- Added `acreate()`, `aget_or_create()`, and `aupdate_or_create()` to
  `GenericRelatedObjectManager` for the same manager-proxy root cause. These
  wrappers delegate to the generic related manager's synchronous methods so
  content type and object id fields are populated consistently.
- Marked the new async methods with `alters_data = True`.

## Assumptions and alternatives considered

- I assumed "related managers" covers reverse foreign key, many-to-many, and
  generic relation managers because all three define relation-specific
  synchronous create/get-or-create/update-or-create methods and inherit the same
  copied queryset async proxies.
- I considered changing `BaseManager._get_queryset_methods()` to make copied
  async queryset methods dispatch back to manager methods, but rejected it
  because that would change manager proxy semantics globally and risk unrelated
  behavior changes.
- I considered only adding `acreate()` because the public issue excerpt showed
  that example first, but the problem statement explicitly names
  `aget_or_create()` and `aupdate_or_create()` as affected, and both have the
  same bypass path.
- I did not modify tests or run tests/code, per the benchmark constraints.
