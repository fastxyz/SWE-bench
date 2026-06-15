# FVK Iteration Guidance

## Verdict

V1 stands unchanged.

The audit found the original defect in the same predicate V1 changed:
`find_ordering_name()` must compare a relation field's `attname` with the final
lookup segment, not the whole lookup path. The public-intent obligations and
constructed proof both support the V1 edit.

## Decisions

D-001: Keep the V1 source edit unchanged.

Rationale:
FINDINGS F-001 and F-002 are resolved by PROOF_OBLIGATIONS PO-001 through
PO-004. The changed predicate is exactly the proof obligation needed for
multi-hop FK attname ordering and direction handling.

D-002: Do not broaden the source change to join construction or
self-referential-FK handling.

Rationale:
PO-003 shows the existing direct branch and `trim_joins()` logic are sufficient
once classification is correct. The self-reference is not itself the semantic
cause; it only makes the erroneous expansion visible as an extra self-join.

D-003: Do not alter relation-name ordering.

Rationale:
FINDINGS F-003 and PO-005 confirm that `record__root` must still use
`OneModel.Meta.ordering`.

D-004: Do not alter direct one-hop FK attname behavior.

Rationale:
FINDINGS F-004 and PO-006 confirm that V1 is behaviorally identical to the
previous implementation for one-segment attnames such as `author_id`.

D-005: Do not modify tests.

Rationale:
The task forbids test edits, and PROOF.md marks the constructed proof as not
machine-checked. Existing and hidden tests remain the evaluator's fixed suite.

## Recommended Next Checks Outside This Session

These are commands or tests for a normal environment; they were not run here:

```sh
kompile fvk/mini-django-ordering.k --backend haskell
kast --backend haskell -I fvk fvk/django-ordering-spec.k
kprove -I fvk fvk/django-ordering-spec.k
```

In Django's test suite, a focused regression test should cover:

- `order_by("record__root_id")` on a self-referential FK with target
  `Meta.ordering`;
- `order_by("-record__root_id")`;
- `order_by("record__root")` as the preserved contrasting behavior; and
- the existing direct `author_id` attname behavior.
