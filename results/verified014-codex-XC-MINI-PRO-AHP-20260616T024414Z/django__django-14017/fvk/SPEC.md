# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited production code is `repo/django/db/models/query_utils.py`, limited
to the behavior changed by V1:

- `Q._combine(self, other, conn)`
- `Q.deconstruct(self)`

The related source used for intent and compatibility is:

- `repo/django/db/models/expressions.py`: boolean expressions with
  `conditional == True` combine by wrapping in `Q`.
- `repo/django/db/models/sql/query.py`: query filters accept conditional
  expressions that resolve as expressions.

The formal model is an abstract mini-Python/K model in `mini-python.k` and
`q-combine-spec.k`. It models the observable relevant to the issue: whether
combination returns a `Q`-shaped result or raises `TypeError`, and whether the
empty-`Q` clone path can deconstruct a wrapped expression.

## Public intent ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. The controlling entries
are:

- E1: `Q(...) & Exists(...)` is an in-domain operation and must not raise the
  pre-fix `TypeError`.
- E2: both `&` and `|` should be symmetric for `Q`/`Exists` pairs.
- E4: public hinted tests cover `Q(salary__gte=30) & Exists(is_ceo)` and
  `Q(salary__lt=15) | Exists(is_poc)`.
- E7: non-conditional plain objects must still raise `TypeError`.

## Contract

For any `self` that is a `Q` object and `conn` in `{AND, OR}`:

1. If `other` is not conditional, `_combine()` raises `TypeError(other)`.
2. If `other` is conditional and not already a `Q`, `_combine()` first wraps it
   as `Q(other)`.
3. If the wrapped `other` is empty, `_combine()` returns a clone of `self`.
4. If `self` is empty and the wrapped `other` is non-empty, `_combine()` returns
   a clone of the wrapped `other`.
5. If both sides are non-empty, `_combine()` returns a `Q` with connector
   `conn` and children containing the left and right conditions according to
   normal `Node.add()` squashing.

For `Q.deconstruct()`:

1. A single lookup tuple child remains serialized through `kwargs`, preserving
   existing behavior.
2. A single non-tuple, non-`Q` child is serialized as a positional arg. This is
   required for `Q(Exists(...))` to be cloned by the empty-`Q` path.
3. A nested `Q` child remains serialized as a positional arg through the
   existing nested branch.

## Out of scope

- SQL generation and database result correctness for every backend.
- Arbitrary user objects that merely define `conditional = True` but are not
  Django boolean expressions. The public issue and internal convention concern
  `Exists` and expression-like conditions.
- Machine-checked proof results. The commands are recorded in `PROOF.md` but
  not executed in this environment.

