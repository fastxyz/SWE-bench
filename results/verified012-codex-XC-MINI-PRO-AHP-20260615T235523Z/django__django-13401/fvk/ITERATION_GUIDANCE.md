# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit found that the V1 source satisfies the owner-sensitive equality,
hash consistency, set-cardinality, and counter-first ordering obligations.
There is no unresolved source-code finding that justifies another edit.

## Recommended Follow-Up Checks

When an execution environment exists, run Django's relevant field/model
inheritance tests and add a focused regression test equivalent to:

- abstract base `A` defines `myfield`;
- concrete `B(A)` and `C(A)` inherit it;
- `B._meta.get_field('myfield') != C._meta.get_field('myfield')`;
- `len({B._meta.get_field('myfield'), C._meta.get_field('myfield')}) == 2`;
- fields with different `creation_counter` values still order by counter first.

Do not remove any tests based on this constructed proof alone.

## FVK Follow-Up

In an environment with K installed, run:

```sh
kompile fvk/mini-field-comparison.k --backend haskell
kast --backend haskell fvk/field-comparison-spec.k
kprove fvk/field-comparison-spec.k
```

If K syntax differences require edits to the `.k` files, make those edits only
to the formal artifacts unless they reveal a new source-level finding.

## UltimatePowers-Style Clarification If Needed

Public intent does not specify ordering for two different model class objects
with the same model label and the same copied creation counter. V1 uses
`id(model)` as a final tie-breaker. If that ordering ever becomes public API,
ask whether same-label distinct model classes should sort by identity,
registry, insertion order, or remain unspecified.
