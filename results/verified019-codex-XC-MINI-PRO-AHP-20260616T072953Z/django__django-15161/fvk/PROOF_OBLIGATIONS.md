# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1: Candidate Class Adequacy

Every class shortened by V1 must be justified by public evidence:

- It is an expression class.
- It is directly importable as `django.db.models.<ClassName>`.
- It already has exact-instance deconstruction through `@deconstructible` on
  itself or an ancestor.

Required class set:

`Expression`, `F`, `OuterRef`, `Func`, `Value`, `ExpressionList`,
`ExpressionWrapper`, `When`, `Case`, `OrderBy`, `Window`, `WindowFrame`,
`RowRange`, and `ValueRange`.

Discharged by: `django/db/models/__init__.py`, `expressions.py`, and FINDING
F-001.

## PO-2: Exact Instance Short Path

For every class `C` in PO-1, exact instances must deconstruct to:

`("django.db.models.C", args, kwargs)`.

Discharged by: explicit `@deconstructible(path='django.db.models.C')`
decorators in `repo/django/db/models/expressions.py`, including the preexisting
`F` decorator and the V1 additions. See claim family `SHORT-PATH-*` in
`fvk/deconstructible-expressions-spec.k`.

## PO-3: Constructor Arguments Preserved

The fix must not alter the positional arguments or keyword arguments returned
by `deconstruct()`.

Discharged by: `django.utils.deconstruct.deconstructible` returns
`obj._constructor_args[0]` and `obj._constructor_args[1]` unchanged in both the
custom path and fallback branches. V1 changes only decorator `path` metadata.

## PO-4: Non-exact Fallback Preserved

Subclasses and internal helper expression classes must keep fallback module
paths unless they are exact instances of their own decorated class.

Discharged by: the `type(obj) is klass` guard in `deconstructible.deconstruct`.
See claim `INTERNAL-FALLBACK-RAWSQL` and FINDING F-002.

## PO-5: Migration Serializer Emits `models.X`

When deconstruction returns a path whose module is `django.db.models`, migration
serialization must render the expression as `models.<ClassName>` with
`from django.db import models`.

Discharged by: `DeconstructableSerializer._serialize_path()` in
`repo/django/db/migrations/serializer.py`, which has a dedicated
`module == "django.db.models"` branch.

## PO-6: No New Deconstruction Contract for `Subquery`/`Exists`

The audit must decide whether V1 should add decorators to `Subquery` and
`Exists`.

Discharged by: FINDING F-003. Public intent supports shortening existing
deconstruction paths. It does not require adding a new `deconstruct()` hook to
query-bearing classes that did not already expose one.

## PO-7: Public Compatibility Frame

The source patch must not alter public signatures, inheritance order,
constructor behavior, SQL rendering, expression resolution, or serializer
dispatch except for exact deconstruction paths.

Discharged by: V1 only adds decorator metadata or changes `Expression`'s
decorator from default to explicit path. No method bodies or signatures changed.
`django.db.models` exports all target names, so the decorator import check can
resolve them.

## PO-8: Honest Verification Boundary

The FVK pass must not claim test execution or machine-checked proof.

Discharged by: all artifacts are labeled constructed, not machine-checked, and
the commands are recorded in `fvk/PROOF.md` without being executed.

