# FVK Specification for django__django-11211

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Scope

This FVK pass audits the V1 production change:

`repo/django/db/models/fields/__init__.py`

```python
def get_prep_value(self, value):
    value = super().get_prep_value(value)
    return self.to_python(value)
```

The behavior under audit is the path from `Bar.objects.all().prefetch_related('foo')` through `GenericForeignKey.get_prefetch_queryset()` and `prefetch_one_level()` when `Bar.foo_object_id` is a textual UUID and the target `Foo.id` is a `UUIDField(primary_key=True)`.

## Intent Spec

I-001, prompt: The issue says "Prefetch related is not working when used GFK for model that uses UUID field as PK" and gives `foo_object_id = models.CharField(...)`, `foo = GenericForeignKey(...)`, and `Bar.objects.all().prefetch_related('foo')`. Obligation: for a valid source object id that denotes an existing target UUID primary key, prefetch must populate `bar.foo` with that target object, not `None`.

I-002, docs: `repo/docs/ref/models/querysets.txt` says `prefetch_related()` "supports prefetching of ... GenericForeignKey" and that prefetch does "the joining in Python." Obligation: the Python join key used by GFK prefetch must compare source ids and related-object pks in the same value domain.

I-003, docs: `repo/docs/ref/contrib/contenttypes.txt` says `GenericForeignKey` cannot be used directly with `filter()` and `exclude()`. Obligation: this fix must not add or rely on direct database filtering support for GFK attributes.

I-004, public tests: `repo/tests/prefetch_related/tests.py` has public GFK prefetch tests, including a non-integer object id case and existing CharField generic relation coverage. Obligation: preserve existing GFK prefetch behavior for non-UUID cases and do not alter test files.

I-005, implementation evidence: `GenericForeignKey.get_prefetch_queryset()` returns `rel_obj_attr = lambda obj: (obj.pk, obj.__class__)` and `instance_attr = gfk_key`, where `gfk_key` uses `model._meta.pk.get_prep_value(getattr(obj, self.fk_field))`. Obligation: for a UUID target primary key, `get_prep_value()` must yield the same Python value form as `obj.pk`.

## Domain

The verified in-domain case is:

- Source instance content type resolves to model `Foo`.
- `Foo._meta.pk` is `UUIDField`.
- Source object id is non-null and is either a `uuid.UUID` object or a valid textual UUID accepted by `UUIDField.to_python()`.
- The corresponding related object is returned by the `pk__in` query and has `obj.pk == uuid.UUID(canonical_source_id)`.
- The model class component of both join keys is the same target model class.

Out-of-domain or frame cases:

- `None` content type or object id remains skipped by existing `GenericForeignKey.get_prefetch_queryset()`.
- Invalid UUID values continue to be handled by `UUIDField.to_python()` raising `ValidationError`.
- Backend-specific database preparation remains in `UUIDField.get_db_prep_value()`.

## Formal Core

The K-style formal core is in:

- `fvk/mini-django-prefetch.k`
- `fvk/django-11211-spec.k`

Claim C-001: `uuidPrep(Str(S)) => UUID(canonUuid(S))` when `validUuid(S)`.

Claim C-002: `keysMatch(Str(S), UUID(canonUuid(S)), Foo) => true` when `validUuid(S)`.

Claim C-003: `uuidPrep(None) => None`.

English adequacy check:

- C-001 exactly models the field-level preparation V1 added.
- C-002 exactly models the issue's failed Python join: source-side textual UUID key must equal related-side UUID primary key key.
- C-003 preserves the existing null frame behavior.

## Public Compatibility Audit

Changed public symbol: `UUIDField.get_prep_value`.

Signature compatibility: no new parameters; this is an override of the base `Field.get_prep_value(self, value)` method.

Return-shape compatibility: valid UUID strings now return `uuid.UUID` objects, matching `UUIDField.to_python()` and the loaded `UUIDField` Python value. `None` remains `None`; invalid values still raise `ValidationError`.

Callsite compatibility: ORM lookup code already calls `get_prep_value()` before `get_db_prep_value(prepared=True)`. `UUIDField.get_db_prep_value()` accepts `uuid.UUID` values and converts to either native UUID or `.hex` depending on backend features.

GFK filter compatibility: no direct `GenericForeignKey` filter/exclude API is changed.
