# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1: Non-default natural-primary deserialization routes related reads to `db`

Given:

- `pk is None`
- `default_manager` has `get_by_natural_key`
- `Model` has `natural_key`
- `natural_key()` performs a related-object read through the temporary instance
- `db` is the database passed by the deserializer

Obligation:

Every related-object read caused by `natural_key()` observes
`instance._state.db == db` and therefore routes through `db`, unless an explicit
router chooses another database.

Status: discharged by V1 setting `obj._state.db = db` before
`obj.natural_key()`.

## PO-2: The pre-fix failure mechanism is removed

Given the reported input class where the related row exists in `other` but not
in `default`, the route to `DEFAULT_DB_ALIAS` must be unreachable from the
temporary instance solely because the instance was newly constructed.

Status: discharged. With `_state.db = db`, the router fallback in
`django/db/utils.py` returns `db` instead of `DEFAULT_DB_ALIAS`.

## PO-3: Natural-primary PK population still uses the target database

Given a computed natural key `nk`, if
`default_manager.db_manager(db).get_by_natural_key(*nk)` returns an object with
primary key `pk`, then `data[Model._meta.pk.attname]` is set to
`Model._meta.pk.to_python(pk)`.

Status: discharged. V1 leaves the manager lookup and PK conversion unchanged.

## PO-4: Existing branch behavior is framed

Obligations:

- If `pk is not None`, do not compute a natural key.
- If the manager lacks `get_by_natural_key`, do not compute a natural key.
- If the model lacks `natural_key`, do not compute a natural key.
- If the target lookup raises `Model.DoesNotExist`, swallow it and return a
  model instance without newly setting the PK.
- In all cases, final object construction remains `Model(**data)`.

Status: discharged. V1 changes only the natural-primary branch before
`natural_key()` is called.

## PO-5: Public compatibility is preserved

Obligations:

- Keep the `build_instance(Model, data, db)` signature.
- Keep return type and caller protocol unchanged.
- Do not require changes in `python.py` or `xml_serializer.py`.

Status: discharged. V1 is an internal implementation change only.

## PO-6: Avoid unnecessary construction semantics changes

Given public intent only requires the temporary natural-key probe to know `db`,
the fix should not introduce unrelated changes to initialization, field
defaults, `adding`, or custom `from_db()` hooks.

Status: discharged by keeping `Model(**data)` and assigning the temporary
object's database state directly.

## K Claim Sketch

The companion `django-15525-spec.k` expresses these obligations as three claim
families:

- `NATURAL-PRIMARY-RELATED-DB`: a missing-PK natural-key-capable model with a
  natural key that follows a relation rewrites to a built object whose observed
  related read and manager lookup both use `DB`.
- `FRAME-PK-PRESENT`: a present-PK call returns the input data unchanged except
  for normal object construction.
- `FRAME-NO-NATURAL`: a model without natural-primary-key support returns the
  input data unchanged except for normal object construction.
