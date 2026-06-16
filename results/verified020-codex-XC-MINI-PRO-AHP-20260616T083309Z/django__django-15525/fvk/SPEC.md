# FVK Specification for django__django-15525

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `django.core.serializers.base.build_instance(Model, data,
db)` on the natural-primary-key branch:

```python
pk is None
and hasattr(default_manager, "get_by_natural_key")
and hasattr(Model, "natural_key")
```

This scope is intent-derived from the issue traceback and the natural-key
documentation. The model includes the helper paths that contribute to the
observable failure:

- `PythonDeserializer` and `xml_serializer.Deserializer` pass the target
  database alias into `build_instance()`.
- `deserialize_fk_value()` already resolves natural foreign keys through
  `db_manager(using)`.
- a `natural_key()` implementation may read a related object through a forward
  relation descriptor.
- relation descriptors route through `db_manager(hints={"instance": obj})`.
- the router uses `instance._state.db` when it is set and otherwise falls back
  to `DEFAULT_DB_ALIAS`.

## Public Intent Ledger

### E1: Non-default load must behave like default load for natural keys

Source: prompt.

Evidence: "It works in the default database, but when I use it a second
database, then I get an exception" and "I wouldn't expect things to work
differently in the default DB and others".

Obligation: deserializing a fixture into `db` must not route natural-key-related
lookups to `default` merely because `db != default`.

Status: encoded in PO-1 and PO-2.

### E2: `loaddata --database` targets the named database

Source: docs.

Evidence: `django-admin loaddata --database DATABASE` "Specifies the database
into which the data will be loaded."

Obligation: helper lookups required to load the object should use the same
database alias that `loaddata` targets unless a public router rule says
otherwise.

Status: encoded in PO-1 and PO-2.

### E3: Missing primary keys are resolved with natural primary keys

Source: docs.

Evidence: "Deserialization of objects with no primary key will always check
whether the model's manager has a `get_by_natural_key()` method and if so, use
it to populate the deserialized object's primary key."

Obligation: if the object has no serialized PK and supports natural primary
keys, `build_instance()` must compute the model natural key and use
`default_manager.db_manager(db).get_by_natural_key()` to populate `data[pk]`
when an existing object is found.

Status: encoded in PO-3.

### E4: Natural keys may include foreign keys

Source: docs and prompt model.

Evidence: docs show `return (self.name,) + self.author.natural_key()` and state
that if a natural key refers to another object "by using a foreign key or
natural key to another object as part of a natural key", dependencies can order
fixtures. The issue model's `Book.natural_key()` returns `(self.title,) +
self.author.natural_key()`.

Obligation: calling `natural_key()` during deserialization is in-domain even
when it follows a foreign key.

Status: encoded in PO-1 and PO-2.

### E5: Related descriptor routing depends on instance database state

Source: implementation.

Evidence: `ForwardManyToOneDescriptor.get_queryset()` calls
`db_manager(hints=hints)`, `get_object()` passes `instance=instance`, and the
router returns `instance._state.db` if present, otherwise `DEFAULT_DB_ALIAS`.

Obligation: the temporary instance used for `natural_key()` must carry the
deserialization database before relation access occurs.

Status: encoded in PO-2.

### E6: Existing non-natural-key behavior is outside the bug and must be framed

Source: implementation and absence of contrary public intent.

Evidence: `build_instance()` skips natural-primary lookup when `pk` is present
or when the model/manager lacks the natural-key methods, and returns
`Model(**data)`.

Obligation: preserve the branch conditions and final object construction for
non-natural-primary-key cases.

Status: encoded in PO-4.

### E7: Public hint identifies the missing database state

Source: prompt public hint.

Evidence: "fix the issue by specifying db before checking natural_key()".

Obligation: the repair may set the temporary instance's database before
`natural_key()`.

Status: encoded in PO-2 and used to justify V1 as an intent-consistent repair.

### E8: Tests are fixed and hidden for this task

Source: user task.

Evidence: "Do not modify any test files" and "do not attempt to run tests".

Obligation: report test recommendations only; do not edit or run tests.

Status: encoded in FINDINGS and PROOF.

## Intent Spec

For every call `build_instance(Model, data, db)`:

1. If `data` already contains the model primary key, the function returns
   `Model(**data)` without natural-primary-key lookup.
2. If either the model manager lacks `get_by_natural_key()` or the model lacks
   `natural_key()`, the function returns `Model(**data)` without
   natural-primary-key lookup.
3. If the model has no serialized primary key and supports natural primary
   keys, the function constructs a temporary instance from `data`, binds that
   temporary instance to `db`, computes `natural_key()` on it, and performs the
   existing-row lookup through `default_manager.db_manager(db)`.
4. Any relation lookup caused by `natural_key()` must see the temporary
   instance's database as `db`; it must not fall back to `DEFAULT_DB_ALIAS`
   solely because the temporary instance was newly constructed.
5. If the natural-primary lookup finds an existing row in `db`, the function
   stores the converted PK into `data[Model._meta.pk.attname]`.
6. If the natural-primary lookup raises `Model.DoesNotExist`, the exception is
   swallowed as before and `data` remains without that PK.
7. The public helper signature and callers remain compatible.

## Formal Core

Companion constructed K artifacts:

- `fvk/mini-django-serializer.k`
- `fvk/django-15525-spec.k`

The formal model abstracts full Python/Django object execution to the state that
distinguishes the bug from the fix: missing or present PK, natural-key support,
target database alias, temporary-instance database state, related-read database,
and manager lookup database. This abstraction is property-complete for the
reported defect because a failing pre-fix execution and a passing V1 execution
map to different `relatedReadDb` and `lookupDb` observations.

Machine-check commands to run later, not executed in this task:

```sh
kompile fvk/mini-django-serializer.k --backend haskell
kast --backend haskell fvk/django-15525-spec.k
kprove fvk/django-15525-spec.k
```

Expected result after a real K run: `#Top` for all claims.
