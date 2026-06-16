# FVK Specification: django__django-14140

Status: constructed from public intent and source inspection; not
machine-checked.

## Target

The audited unit is `django.db.models.query_utils.Q.deconstruct()` and the
`Q._combine()` clone path that depends on `deconstruct()` when combining with an
empty `Q()`.

There are no loops in the audited unit. The proof is a branch proof over the
`deconstruct()` conditional.

## Intent-Only Contract

`Q.deconstruct()` must return a triple `(path, args, kwargs)` that can be used to
reconstruct an equivalent `Q` object for the supported `Q` shapes in this issue:

1. Ordinary single lookup conditions keep the existing backwards-compatible
   kwargs format.
2. Multiple conditions use positional `args`.
3. Nested `Q` children use positional `args`.
4. Conditional expression children, including `Exists(...)`, use positional
   `args` and must not be indexed as lookup pairs.
5. Negation is preserved with `_negated=True`.
6. Non-default connectors are preserved on the positional-argument path.

Unsupported arbitrary non-conditional children such as `Q(False)` are outside
the repaired domain. They are mentioned in the issue discussion as fragile
legacy behavior, but the public hint narrows the required fix to conditional
expressions while keeping the current deconstruction format.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`

Quote: "`Q(x=1).deconstruct()` -> `('django.db.models.Q', (), {'x': 1})`."

Obligation: preserve kwargs output for the ordinary one-lookup case.

Status: encoded by PO-1.

E2. Source: `benchmark/PROBLEM.md`

Quote: "`Q(x=1, y=2).deconstruct()` -> `('django.db.models.Q', (('x', 1), ('y', 2)), {})`."

Obligation: multiple lookup conditions stay positional.

Status: encoded by PO-4.

E3. Source: `benchmark/PROBLEM.md`

Quote: "`Q(Exists(...)).deconstruct()` ... `TypeError: 'Exists' object is not subscriptable`."

Obligation: a single conditional expression child must not be indexed as
`child[0]` / `child[1]`.

Status: encoded by PO-2 and resolved by the V1 guard.

E4. Source: `benchmark/PROBLEM.md` public hint

Quote: "There is no need to change the current format of `deconstruct()`, it
should be enough to handle conditional expressions."

Obligation: fix conditional expression children without removing the
single-lookup kwargs special case.

Status: encoded by PO-1, PO-2, and FINDING F-002.

E5. Source: `repo/tests/queries/test_q.py`

Quote: `test_deconstruct()` asserts `args == ()` and
`kwargs == {'price__gt': F('discounted_price')}` for a single lookup.

Obligation: public tests reinforce the backwards-compatible single-lookup
format.

Status: encoded by PO-1.

E6. Source: `repo/tests/queries/test_q.py`

Quote: `test_deconstruct_nested()` asserts `args == (Q(...),)` for `Q(Q(...))`.

Obligation: nested `Q` children are positional.

Status: encoded by PO-3.

E7. Source: `repo/django/db/models/query_utils.py`

Quote: `Q.conditional = True`; `Q._combine()` accepts `getattr(other,
'conditional', False) is True`.

Obligation: use Django's existing conditional-expression protocol rather than a
special case for `Exists`.

Status: encoded by PO-2 and PO-5.

E8. Source: `repo/django/db/models/expressions.py`

Quote: boolean expression operators return `Q(self) & Q(other)` /
`Q(self) | Q(other)` when both operands are conditional.

Obligation: a conditional expression wrapped as a `Q` child must be serializable
on the same positional path as other non-lookup children.

Status: encoded by PO-2 and PO-5.

## Abstract Model

The proof models only the observable data needed by `Q.deconstruct()`:

- `Q(children, connector, negated, class_path)`
- `conditional(child)`, which returns exactly the same boolean marker used by
  Django's expression-combination code.
- `lookup_key(child)` and `lookup_value(child)`, defined only for lookup-pair
  children.
- `default_connector = "AND"`.

The modeled implementation is:

```text
path = canonical_path(Q)
args = ()
kwargs = {}
if len(children) == 1 and conditional(children[0]) is False:
    child = children[0]
    kwargs = {lookup_key(child): lookup_value(child)}
else:
    args = tuple(children)
    if connector != default_connector:
        kwargs = {"_connector": connector}
if negated:
    kwargs["_negated"] = True
return (path, args, kwargs)
```

The V1 source matches this model at
`repo/django/db/models/query_utils.py:83`.

## Expected Behavior by Input Class

1. `Q(x=1)`:
   returns `('django.db.models.Q', (), {'x': 1})`.

2. `Q(x=1, y=2)`:
   returns `('django.db.models.Q', (('x', 1), ('y', 2)), {})`, with the child
   order determined by `Q.__init__()` sorting keyword items.

3. `Q(Q(x=1))`:
   returns `('django.db.models.Q', (Q(x=1),), {})`.

4. `Q(Exists(...))` or any supported conditional expression child:
   returns `('django.db.models.Q', (child,), {})` unless connector or negation
   adds kwargs. It does not attempt `child[0]`.

5. `~Q(Exists(...))`:
   returns args `(child,)` and kwargs `{'_negated': True}`.

6. `Q(Exists(...), _connector='OR')`:
   returns args `(child,)` and kwargs `{'_connector': 'OR'}`.

7. `Q(False)`:
   remains outside the repaired contract. The issue mentions unsupported inputs,
   but the accepted public hint narrows the production fix to conditional
   expressions and backwards-compatible deconstruction output.

