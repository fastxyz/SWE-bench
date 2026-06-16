# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What is proved

For the audited `build_instance()` branch, if a deserialization call targets
database `db` and needs to compute a model natural key before natural-primary
lookup, then the temporary instance used for `natural_key()` is database-bound
to `db`. Therefore any forward foreign-key read performed by that
`natural_key()` routes with `instance._state.db == db`, not with an empty state
that falls back to `DEFAULT_DB_ALIAS`.

The proof also frames unchanged behavior: present-PK calls, models without
natural-primary-key support, `DoesNotExist` handling, public signature, caller
protocol, and final `Model(**data)` construction.

## Symbolic Proof

### Branch selection

Assume `pk is None`, the default manager has `get_by_natural_key`, and the model
has `natural_key`. These are exactly the branch conditions in `build_instance()`.
Other branches are handled by PO-4.

### Temporary instance construction

Before V1, `Model(**data)` produced a temporary object with default model state:
`_state.db == None`.

In V1:

```python
obj = Model(**data)
obj._state.db = db
natural_key = obj.natural_key()
```

The only changed symbolic state before `natural_key()` is the temporary object's
database field.

### Related lookup inside `natural_key()`

For an in-domain natural key such as:

```python
return (self.title,) + self.author.natural_key()
```

`self.author` invokes the forward related descriptor. The descriptor calls
`get_queryset(instance=instance)`, which passes the instance as a database
router hint. The router rule is:

```python
if instance is not None and instance._state.db:
    return instance._state.db
return DEFAULT_DB_ALIAS
```

Substituting the V1 state gives `instance._state.db == db`, so the related read
routes to `db`. The pre-fix substitution gave `None`, so the fallback was
`DEFAULT_DB_ALIAS`. This discharges PO-1 and PO-2.

### Natural-primary manager lookup

After `natural_key()` returns, V1 executes the unchanged lookup:

```python
default_manager.db_manager(db).get_by_natural_key(*natural_key).pk
```

If the object exists, its primary key is converted and assigned to `data[pk]`.
If it raises `Model.DoesNotExist`, the exception is swallowed. This discharges
PO-3 and the `DoesNotExist` part of PO-4.

### Frame cases

If `pk is not None`, or the manager/model natural-key capability checks fail,
control skips the modified block exactly as before. The return statement remains
`return Model(**data)`. This discharges PO-4 and PO-6.

### Compatibility

The helper signature and both public in-repo callsites are unchanged:

- `python.py` calls `base.build_instance(Model, data, using)`.
- `xml_serializer.py` calls `base.build_instance(Model, data, self.db)`.

No callsite or override protocol changes are introduced. This discharges PO-5.

## Adequacy Check

The formal claim says that the database alias used for related reads during
natural-key computation is the same alias passed to `build_instance()`. That is
not candidate-derived: it comes from the issue's non-default database failure,
the `loaddata --database` docs, the natural-key docs, and the public hint.

The claim does not over-specify router behavior when a user-defined router
explicitly chooses another database before the default instance-state fallback.
The concrete source evidence under audit is the default fallback path triggered
by an unset `_state.db`.

## Test Recommendation

Do not remove tests. A regression test should be added in normal development:
load a natural-primary fixture into a non-default database where the model
natural key follows a foreign key and the related row exists only in the target
database. This task forbids test edits, so no test file was changed.

## Machine Check Commands

These commands were not run:

```sh
kompile fvk/mini-django-serializer.k --backend haskell
kast --backend haskell fvk/django-15525-spec.k
kprove fvk/django-15525-spec.k
```

Expected result after a real K run: `#Top` for all claims.

## Residual Risk

This is a partial-correctness proof over an abstract mini semantics of the
serializer path, not a machine-checked proof over full Python and Django. The
trusted base is the adequacy of the abstraction, the source-code readings cited
in `SPEC.md`, and a future K run of the emitted artifacts.
