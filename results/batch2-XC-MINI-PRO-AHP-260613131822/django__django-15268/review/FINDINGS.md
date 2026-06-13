# Code review — django__django-15268 (V1 fix)

## Fix under review

`django/db/migrations/operations/models.py`, `AlterTogetherOptionOperation` (lines 531–535):

```python
def reduce(self, operation, app_label):
    return super().reduce(operation, app_label) or (
        isinstance(operation, AlterTogetherOptionOperation) and
        self.name_lower == operation.name_lower
    )
```

This is the only production change in V1. The review below is organized as numbered
findings. The overall verdict is at the end.

---

## F1 — Correctness against the issue (PASS)

Traced the optimizer (`optimizer.py: optimize_inner`) on the exact 4-operation example
from `PROBLEM.md`:

```
op0 AlterUniqueTogether('mymodel', set())
op1 AlterIndexTogether('mymodel', set())
op2 AlterUniqueTogether('mymodel', {('col',)})
op3 AlterIndexTogether('mymodel', {('col',)})
```

* Pass 1: `op0.reduce(op1)` now returns `True` (different together-subtype, same model),
  so `right` stays `True`; `op0.reduce(op2)` returns `[op2]` (same subclass via
  `super()`), so the right-reduction fires → `[op1, op2, op3]`.
* Pass 2: same mechanism collapses the index pair → `[op2, op3]`.
* Pass 3: no further change.

Final output `[AlterUniqueTogether('mymodel', {('col',)}), AlterIndexTogether('mymodel',
{('col',)})]` — exactly the expected result. The headline requirement is met.

## F2 — State-level independence is real (PASS)

`AlterTogetherOptionOperation.state_forwards` calls
`state.alter_model_options(app_label, name, {self.option_name: self.option_value})` with
`option_keys=None`. `ModelState.alter_model_options` (state.py:170) does
`options = {**options, **{option_name: value}}` and skips the pop-loop when `option_keys`
is falsy. So an `AlterUniqueTogether` only writes the `unique_together` key and an
`AlterIndexTogether` only writes `index_together`. The two keys are disjoint ⇒ reordering
the two operations yields identical final model options. The `reduce()==True`
("can optimize across") claim is therefore valid at the state level.

## F3 — Database-level independence is real (PASS)

`database_forwards` dispatches to `schema_editor.alter_unique_together` vs
`alter_index_together`, and each reads its *own* option from `from_state`/`to_state`
(`getattr(model._meta, self.option_name, set())`). Unique constraints and (non-unique)
`index_together` indexes are distinct database objects with distinct generated names on
every backend (even on MySQL, where a unique constraint is a separate unique index from
the index_together index). Dropping/creating one never affects the other, so the two
operations commute against a live database, including when they touch the same columns.

## F4 — Existing "two of the same collapse into the second" is preserved (PASS)

For two operations of the *same* subclass on the same model, `super().reduce`
(`ModelOptionOperation.reduce`, line 411) returns `[operation]`, a truthy list, so the
`or` short-circuits and the new clause is never evaluated. Tests
`test_alter_alter_unique_model` / `test_alter_alter_index_model` continue to hold. The
`AlterFooTogether` → `DeleteModel` collapse (also `[operation]` from `super()`) is likewise
untouched.

## F5 — Different-model behavior is preserved (PASS)

When `operation` targets a *different* model, `super().reduce` reaches
`ModelOperation.reduce` (line 34) and returns `not operation.references_model(self.name)`
= `True`. The `or` short-circuits, and the new clause's `self.name_lower ==
operation.name_lower` guard would be `False` anyway. No change for cross-model cases.

## F6 — The #31503 split is preserved when a real field op intervenes (PASS, key safety check)

The whole reason the remove/add split exists is so an intervening field alteration works.
Verified that the optimizer still refuses to collapse across such an op:

For `AddField('m','newfield')` between `AlterUniqueTogether('m', set())` and
`AlterUniqueTogether('m', {('newfield',)})`:
* `op0.reduce(AddField)` = `False` (AddField is not an `AlterTogetherOptionOperation` and
  references model `m`) ⇒ `right` becomes `False`, blocking the right-reduction.
* The left-reduction's `all(op.reduce(other) is True …)` check includes the AddField, and
  `AddField.reduce(AlterUniqueTogether-referencing-newfield)` = `False`: `AddField.reduce`
  (fields.py:119) falls through to `FieldOperation.reduce` (fields.py:56), which returns
  `not operation.references_field('m','newfield')`; `AlterTogetherOptionOperation.
  references_field` returns `True` because `newfield` appears in the option value.

So the collapse correctly does NOT happen when a dependent field op sits between the pair.
V1 only collapses when the *only* thing between the two same-type ops is the independent
other-type op. No #31503 regression.

## F7 — Scope is appropriately conservative (PASS)

The new clause fires only for `isinstance(operation, AlterTogetherOptionOperation)`, i.e.
`AlterUniqueTogether`/`AlterIndexTogether`. It does NOT relax optimization across
`AlterOrderWithRespectTo`, `AlterModelTable`, or `AlterModelOptions` (none are
`AlterTogetherOptionOperation`), so those remain conservatively non-commutable on the same
model. This matches the issue's scope (only AlterFooTogether) and avoids asserting
commutativity for operations whose independence is less clear-cut (e.g.
order_with_respect_to adds a real `_order` field).

## F8 — No optimization is lost (PASS)

The change only converts a `False` return to `True` for one case (F5/F1). It never removes
or alters a list result (those come from `super()`, evaluated first). Returning `True`
strictly *enables* additional reorderings/reductions; it can never disable an existing one.

## F9 — Termination / stability of the optimizer is preserved (PASS)

The outer loop (`optimizer.py: optimize`) terminates when a pass makes no change. A pure
`reduce()==True` return performs no reordering by itself — reordering of in-between ops
only happens bundled with a *list* reduction, and every list reduction produced via this
path is `[operation]` (length 1) replacing two operations, strictly shortening the list.
Since length strictly decreases on every structural change and is bounded below, no
oscillation/infinite loop is introduced.

## F10 — `reduce()` contract compliance (PASS)

`Operation.reduce`'s contract (base.py:123) is "list of replacements OR a boolean
optimize-across flag." The expression returns `super().reduce(...)` (a non-empty list or a
boolean) when truthy, else the boolean from the new clause. For this class hierarchy
`super().reduce` never returns an empty list (`ModelOptionOperation.reduce` returns
`[operation]` or a `ModelOperation`/`Operation` boolean; `elidable` is `False`), so the
`or` has no "empty-list discarded" pitfall. Boolean/list contract upheld.

## F11 — Consistency with codebase conventions (PASS)

* Idiom `return super().reduce(operation, app_label) or (<condition>)` mirrors
  `ModelOperation.reduce` (line 34) and `RenameModel.reduce` (line 404).
* `reduce` is placed last in the class, matching `CreateModel`, `RenameModel`,
  `ModelOperation`, `ModelOptionOperation`.
* Referencing `AlterTogetherOptionOperation` by name inside a method is already done by
  `CreateModel.reduce` (line 153); name resolution at call time against module globals is
  safe.
* `self.name_lower` is the established lowercase-compare accessor (cached_property on
  `ModelOperation`).

## F12 — Error handling (PASS)

`reduce` has no exception-raising paths: `isinstance` and `self.name_lower ==
operation.name_lower` are total. `name_lower` is always present on any `ModelOperation`
subclass (`operation` here is only meaningfully compared when it is an
`AlterTogetherOptionOperation`, which has it). No `None`/attribute hazards.

## F13 — Forward-looking design note (INFORMATIONAL, not a defect)

The fix lives on the base class and treats *all* `AlterTogetherOptionOperation` subclasses
as mutually independent. This is correct by construction for the only two subclasses today
(each manages exactly one distinct `_meta` option / one distinct class of DB object). If a
future subclass were added that did NOT manage an independent single option, this blanket
commutativity could become unsafe. This is a property of the class abstraction, not a bug
in the current change; no action needed now.

---

## Verdict

No correctness, edge-case, regression, contract, or convention defects were found. The V1
change is minimal, idiomatic, and provably safe (F2/F3 independence; F6 preserves #31503).
**V1 stands unchanged.** A gratuitous edit (e.g., an explanatory inline comment) would
break the file's terse `reduce`-method convention (F11) and is therefore declined.
