# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## What Is Proved

The proof covers the reference-scope transformation introduced by `Query.split_exclude()` for negated many-valued relation lookups.

It proves:

- An existing user `OuterRef('pk')` is shifted so it binds to the enclosing query after the generated split-exclude subquery is introduced.
- A plain local `F()` value still binds to the immediate parent query.
- A non-expression RHS remains unchanged.
- The pre-V1 behavior binds the reported `OuterRef('pk')` to the wrong immediate parent query level.

## Symbolic Proof: OUTERREF-SHIFT

Goal:

```text
pipeline(OuterRef(FRef("pk")), 0, 1, 2) => Bound(2, "pk")
```

Reduction:

```text
pipeline(OuterRef(FRef("pk")), 0, 1, 2)
=> resolveStep(resolveStep(resolveStep(splitShift(OuterRef(FRef("pk"))), 0), 1), 2)
=> resolveStep(resolveStep(resolveStep(OuterRef(OuterRef(FRef("pk"))), 0), 1), 2)
=> resolveStep(resolveStep(OuterRef(FRef("pk")), 1), 2)
=> resolveStep(Resolved("pk"), 2)
=> Bound(2, "pk")
```

Interpretation:

V1 inserts one additional `OuterRef` wrapper. The first generated-query resolution consumes only that wrapper, the immediate-parent resolution converts the original `OuterRef` to a `ResolvedOuterRef`, and the enclosing-query resolution binds it to the intended outer query level.

## Symbolic Proof: PLAIN-F-PRESERVED

Goal:

```text
pipeline(FRef("local_field"), 0, 1, 2) => Bound(1, "local_field")
```

Reduction:

```text
pipeline(FRef("local_field"), 0, 1, 2)
=> resolveStep(resolveStep(resolveStep(splitShift(FRef("local_field")), 0), 1), 2)
=> resolveStep(resolveStep(resolveStep(OuterRef(FRef("local_field")), 0), 1), 2)
=> resolveStep(resolveStep(Resolved("local_field"), 1), 2)
=> resolveStep(Bound(1, "local_field"), 2)
=> Bound(1, "local_field")
```

Interpretation:

Plain `F()` values retain the existing behavior: they are shifted once to refer to the immediate parent query.

## Symbolic Proof: NON-EXPRESSION-PRESERVED

Goal:

```text
pipeline(Literal("rhs"), 0, 1, 2) => Literal("rhs")
```

Reduction:

```text
pipeline(Literal("rhs"), 0, 1, 2)
=> resolveStep(resolveStep(resolveStep(splitShift(Literal("rhs")), 0), 1), 2)
=> resolveStep(resolveStep(resolveStep(Literal("rhs"), 0), 1), 2)
=> resolveStep(resolveStep(Literal("rhs"), 1), 2)
=> resolveStep(Literal("rhs"), 2)
=> Literal("rhs")
```

Interpretation:

The V1 branch does not affect non-expression RHS values.

## Symbolic Proof: V0-COUNTEREXAMPLE

Goal:

```text
pipelineV0(OuterRef(FRef("pk")), 0, 1, 2) => Bound(1, "pk")
```

Reduction:

```text
pipelineV0(OuterRef(FRef("pk")), 0, 1, 2)
=> resolveStep(resolveStep(resolveStep(splitShiftV0(OuterRef(FRef("pk"))), 0), 1), 2)
=> resolveStep(resolveStep(resolveStep(OuterRef(FRef("pk")), 0), 1), 2)
=> resolveStep(resolveStep(Resolved("pk"), 1), 2)
=> resolveStep(Bound(1, "pk"), 2)
=> Bound(1, "pk")
```

Interpretation:

The old shape consumes the original `OuterRef` one level too early, so it binds to the immediate parent query. This matches the public hint that the generated SQL used the `Item` alias instead of the `Number` alias.

## Machine-Check Commands

These commands are emitted for a suitable environment. They were not run here.

```sh
cd fvk
kompile mini-orm-scope.k --backend haskell
kast --backend haskell outerref-split-exclude-spec.k
kprove outerref-split-exclude-spec.k
```

Expected outcome: `kprove` discharges the claims to `#Top`.

## Residual Risk

This is a partial, abstract proof over the scope-preservation slice. It does not prove full Django ORM SQL generation, database execution, termination, or query planner behavior. Those remain covered by normal Django tests in an execution-capable environment.

## Test Guidance

No tests should be removed based on this constructed proof. Relevant tests to keep or add in a normal development environment are:

- `Exists(Item.objects.exclude(tags__category_id=OuterRef('pk')))` under an outer `Number` query.
- `Exists(Item.objects.filter(~Q(tags__category_id=OuterRef('pk'))))` under an outer `Number` query.
- A plain `F()` regression for `split_exclude()` to confirm PO3.
