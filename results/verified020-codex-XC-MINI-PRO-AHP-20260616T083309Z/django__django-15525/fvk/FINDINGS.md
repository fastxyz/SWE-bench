# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-V1 database routing bug in `natural_key()`

Classification: code bug, fixed by V1.

Evidence: E1, E2, E4, E5, E7. Proof obligations: PO-1, PO-2, PO-3.

Input:

- target database alias: `other`
- default database lacks the related `Author`
- `other` contains the related `Author`
- fixture has no serialized `Book` PK and uses natural foreign keys
- `Book.natural_key()` reads `self.author.natural_key()`

Observed before V1:

`build_instance()` constructed `Model(**data)` with `_state.db == None`.
`self.author` then routed through the related descriptor and router to
`DEFAULT_DB_ALIAS`, causing `Author.DoesNotExist` when the author existed only
in `other`.

Expected:

The related lookup performed while computing `natural_key()` must use `other`,
the database passed to `build_instance()` by `loaddata --database other`.

V1 status:

V1 sets `obj._state.db = db` before `obj.natural_key()`. The router therefore
uses `other` for related reads, and the subsequent natural-primary lookup is
already executed through `default_manager.db_manager(db)`.

## F2: V1 should preserve final instance construction

Classification: frame condition, confirmed.

Evidence: E3, E6. Proof obligations: PO-3, PO-4, PO-6.

Input:

- any deserialized model data, including omitted fields with defaults
- any branch where `build_instance()` returns an object after optional PK
  population

Observed in V1:

The temporary object is database-bound only for natural-key computation. The
returned object is still constructed by the original `return Model(**data)`.

Expected:

The fix should not replace normal model initialization or change final
construction semantics for unrelated fields.

V1 status:

Confirmed. This is a reason to keep V1's direct temporary-state binding instead
of replacing construction with `Model.from_db()`.

## F3: `Model.from_db()` alternative is not required by public intent

Classification: rejected alternative, no source change.

Evidence: E6, E7. Proof obligations: PO-4, PO-6.

Input:

- a model with omitted fields, defaults, or a custom `from_db()` implementation
- fixture data that relies on normal `Model(**data)` initialization

Observed risk in the alternative:

Using `Model.from_db()` for the natural-key probe would mark the probe object as
loaded from the database (`adding = False`) and may invoke custom `from_db()`
behavior. It can also differ from `Model(**data)` when not all concrete fields
are supplied.

Expected:

Only the missing database routing context should change.

V1 status:

Confirmed. V1 preserves `Model(**data)` behavior and adds only `_state.db = db`
to the temporary probe object.

## F4: Public API compatibility has no open issue

Classification: compatibility check, confirmed.

Evidence: E6. Proof obligation: PO-5.

Input:

- public in-repo callsites in `python.py` and `xml_serializer.py`

Observed in V1:

`build_instance(Model, data, db)` keeps the same signature, return shape, and
exception handling. Existing callsites continue passing the target database.

Expected:

No caller or subclass update is required.

V1 status:

Confirmed.

## F5: Tests are recommended but not modified in this task

Classification: test gap imposed by task constraints.

Evidence: E8.

Recommended test:

A regression test should load a natural-primary-key fixture into a non-default
database where a model natural key follows a foreign key, with the related row
present only in the target database.

Status:

Not implemented because this task forbids modifying tests. Test removal is not
recommended because the proof is constructed, not machine-checked, and the
coverage here is a bug-fix regression.

## Proof-derived findings from `/verify`

No additional code defect was derived beyond F1. The constructed proof closes
the stated obligations under the abstraction in `SPEC.md`, subject to the
honesty caveat that K was not run. The only residual risks are the trusted
abstraction boundary and lack of machine checking.
