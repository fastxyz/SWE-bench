# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 change for the issue "Use simplified paths for
deconstruct of expressions." The target behavior is the import path returned by
the `deconstruct()` method installed by `django.utils.deconstruct.deconstructible`
on Django expression classes.

There are no loops in the changed code. The only transition modeled is the
branch inside generated `deconstruct(obj)`:

- If the decorator has a custom `path` and `type(obj) is klass`, return that
  custom path and preserve constructor args/kwargs.
- Otherwise, return the fallback module path for the object's actual class and
  preserve constructor args/kwargs.

## Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "`F()` deconstructed to: `django.db.models.expressions.F()` ... changed it to deconstruct to `django.db.models.F()`." | A class directly importable from `django.db.models` should use the shorter `django.db.models.<ClassName>` path when exact-instance deconstruction is available. | Encoded by PO-1 and PO-2. |
| I2 | prompt | "the same technique can be applied to other expressions" | Apply the `F` path-shortening technique to comparable expression classes, not just `F`. | Encoded by the candidate class set. |
| I3 | source | `django/db/models/__init__.py` imports expression classes into `django.db.models`. | The safe short-path candidates are root-exported expression classes. | Encoded by candidate set and compatibility audit. |
| I4 | source | `deconstructible(path=...)` uses `path` only when `type(obj) is klass`; otherwise it falls back to `obj.__module__`. | Exact instances get the short path; subclasses/internal helpers keep fallback paths. | Encoded by PO-2, PO-3, and PO-4. |
| I5 | source | migration serializer maps module `django.db.models` to `from django.db import models` and `models.<name>`. | Returning `django.db.models.<ClassName>` produces the desired simplified migration code. | Encoded by PO-5. |
| I6 | source | `Subquery` and `Exists` are root-exported but do not currently inherit or define `deconstruct()`. | The issue supports simplifying existing expression deconstruction paths, not creating new deconstruction support for query-bearing expressions. | Encoded by PO-6 and FINDING F-003. |

## Domain

The verified in-domain class set is:

`Expression`, `F`, `OuterRef`, `Func`, `Value`, `ExpressionList`,
`ExpressionWrapper`, `When`, `Case`, `OrderBy`, `Window`, `WindowFrame`,
`RowRange`, and `ValueRange`.

Each class in this set is directly exported from `django.db.models` and has a
`deconstruct()` implementation through `@deconstructible` on itself or an
ancestor.

Out of domain:

- `Subquery` and `Exists`, because V1 intentionally does not add a new
  `deconstruct()` hook to classes that did not have one.
- Internal or non-root-exported helpers such as `CombinedExpression`, `RawSQL`,
  `Star`, `Col`, `Ref`, `OrderByList`, `DurationExpression`,
  `TemporalSubtraction`, and `ResolvedOuterRef`.

## Contract

For each in-domain class `C`, and for any constructor argument tuple `A` and
keyword dictionary `K`, exact instance deconstruction satisfies:

`C(*A, **K).deconstruct() == ("django.db.models.C", A, K)`.

For any object whose actual type is not the exact decorated class, the fallback
path remains:

`"<obj.__class__.__module__>.<obj.__class__.__name__>"`.

Constructor arguments and keyword arguments are preserved exactly as captured by
`deconstructible.__new__`; the V1 change does not alter constructors, expression
resolution, SQL generation, output fields, copying, equality, hashing, or model
index/constraint behavior.

## Formal Core

The companion formal files are:

- `fvk/mini-python-deconstruct.k`
- `fvk/deconstructible-expressions-spec.k`

The K model abstracts Python down to the exact branch that matters for this
change: the custom-path exact-type branch and the fallback branch. This
abstraction keeps the verified observable, the deconstructed import path, fully
represented.

