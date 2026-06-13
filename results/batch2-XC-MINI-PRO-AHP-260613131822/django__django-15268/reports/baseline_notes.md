# Baseline notes — django__django-15268

## Issue

Optimize multiple `AlterFooTogether` operations into one.

Since #31503, the autodetector splits each `AlterUniqueTogether` / `AlterIndexTogether`
change into two operations: first a "remove" operation (sets the option to the
intersection of old & new, dropping constraints that are going away), and later an "add"
operation (sets the option to the new value). This split lets field alterations that occur
in between work correctly.

When there is nothing meaningful between the remove and add operations, the two should
collapse into a single operation. The migration optimizer fails to do this for the
interleaved pattern the autodetector actually emits:

```python
operations = [
    migrations.AlterUniqueTogether(name='mymodel', unique_together=set()),       # remove
    migrations.AlterIndexTogether(name='mymodel', index_together=set()),         # remove
    migrations.AlterUniqueTogether(name='mymodel', unique_together={("col",)}),  # add
    migrations.AlterIndexTogether(name='mymodel', index_together={("col",)}),    # add
]
```

This should optimize to just the two "add" operations.

## Root cause

The optimizer (`django/db/migrations/optimizer.py`) reduces two operations that are
separated by others only if every in-between operation can be "optimized across" — i.e.
`in_between_op.reduce(other, app_label)` returns `True`.

The two `AlterUniqueTogether` operations (op0 and op2) are separated by an
`AlterIndexTogether` (op1). The optimizer cannot collapse op0/op2 because:

* `ModelOptionOperation.reduce` returns the collapsed `[operation]` only when `operation`
  is an instance of the *same* class (`self.__class__`) on the same model. Two
  `AlterUniqueTogether` ops match this, but the in-between `AlterIndexTogether` is a
  different class.
* For a *different* `AlterFooTogether` subclass on the *same* model, `reduce` fell through
  to `ModelOperation.reduce`, which returns `not operation.references_model(self.name)`.
  Since both touch the same model, `references_model` is `True`, so `reduce` returned
  `False` ("cannot optimize across"). The optimizer therefore stopped and left all four
  operations in place.

That `False` is overly conservative: an `AlterUniqueTogether` and an `AlterIndexTogether`
are independent. `state_forwards` for each touches only its own model option
(`unique_together` vs `index_together`), and `database_forwards` for each alters only its
own kind of database object (unique constraints vs indexes). They can be freely reordered
without changing the resulting state or schema.

## Change

**File: `django/db/migrations/operations/models.py`**

Added a `reduce` method to `AlterTogetherOptionOperation` (the shared base class of
`AlterUniqueTogether` and `AlterIndexTogether`):

```python
def reduce(self, operation, app_label):
    return super().reduce(operation, app_label) or (
        isinstance(operation, AlterTogetherOptionOperation) and
        self.name_lower == operation.name_lower
    )
```

Behavior:

* `super().reduce(...)` (`ModelOptionOperation.reduce`) still runs first and returns
  `[operation]` when the other op is the *same* `AlterFooTogether` subclass on the same
  model — so the existing "two of the same collapse into the second" optimization is
  unchanged (the truthy list short-circuits the `or`).
* When the other op is a *different* `AlterFooTogether` subclass on the *same* model,
  `super().reduce` returns `False`, and the added clause now returns `True`, telling the
  optimizer these operations are independent and may be optimized across each other.
* Different models are already handled by `ModelOperation.reduce`
  (`not references_model` → `True`); the added clause requires a matching `name_lower`, so
  it only relaxes the same-model / different-subtype case.

With this, the optimizer can move the in-between `AlterIndexTogether` aside, collapse the
two `AlterUniqueTogether` ops (right reduction), then collapse the two
`AlterIndexTogether` ops on the next pass — producing the expected two-operation result.

## Why the fix belongs here (alternatives considered and rejected)

* **Change the optimizer.** Rejected — the optimizer is intentionally generic. Knowledge
  of which operations are mutually independent belongs in each operation's `reduce`,
  consistent with how every other operation expresses this.
* **Narrow `references_model` / `references_field` to ignore the other option type.**
  Rejected — `references_model` is used widely (dependency tracking, field-operation
  boundaries, etc.). Loosening it could silently produce unusable migrations. The `reduce`
  override is surgical and only affects the optimizer's across-check.
* **Fix the autodetector so it never emits the redundant pair.** Rejected — the
  remove-then-add split from #31503 is deliberate so that in-between field alterations
  stay correct. Collapsing belongs in the optimizer, which only collapses when it is
  provably safe (nothing depends on the intermediate state). Touching the autodetector
  would risk regressing #31503.

## Assumptions

* `AlterUniqueTogether` and `AlterIndexTogether` are the only subclasses of
  `AlterTogetherOptionOperation` (confirmed in `operations/models.py`), and they operate
  on independent model options and independent database objects, so reordering them is
  always safe.
* Tests are fixed/hidden and must not be modified; the existing optimizer tests
  (`test_alter_alter_unique_model`, `test_alter_alter_index_model`) continue to pass
  because the same-subclass collapse path is untouched.
