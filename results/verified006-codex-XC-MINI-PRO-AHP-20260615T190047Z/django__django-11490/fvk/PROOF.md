# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Claim

V1 satisfies the intent specification for django__django-11490:

1. During a single combined-query compilation, children without their own
   `values_select` receive the outer selected field list.
2. That temporary selected field list does not mutate the original child query
   objects stored in `combined_queries`.
3. Repeated evaluations of the same combined queryset with different
   `values()` / `values_list()` selections are independent.

## Symbolic counterexample on the pre-fix mechanism

Let child query `C` start with:

```text
C.values_select = empty
C.select = default model columns
```

Let the reusable combined query have `combined_queries = (C, C)`.

First evaluation:

```py
combined.values_list('name', 'order')
```

The outer query has selected fields `F1 = [name, order]`. In the pre-fix
compiler, child compilers point directly at `C`. The branch
`not compiler.query.values_select and self.query.values_select` is true, so
`set_values(F1)` mutates `C` itself:

```text
C.values_select = [name, order]
C.select = [name, order]
```

Second evaluation:

```py
combined.values_list('order')
```

The outer query has selected fields `F2 = [order]`, but the child query `C`
already has non-empty `values_select` from the first evaluation. The branch
condition is false, so the compiler keeps the stale child selection
`[name, order]`. This derives Finding F-001 from the source mechanism and the
public issue example.

## Symbolic execution of V1

V1 changes child compiler creation from:

```py
query.get_compiler(self.using, self.connection)
```

to:

```py
query.clone().get_compiler(self.using, self.connection)
```

First evaluation with `F1 = [name, order]`:

```text
K1 = clone(C)
K1.values_select = empty
branch condition true
set_values(F1) mutates K1
C remains unchanged
```

The generated child SQL uses `K1.select = [name, order]`, satisfying PO-1.
The stored child query remains:

```text
C.values_select = empty
C.select = default model columns
```

Second evaluation with `F2 = [order]`:

```text
K2 = clone(C)
K2.values_select = empty
branch condition true
set_values(F2) mutates K2
C remains unchanged
```

The generated child SQL now uses `K2.select = [order]`. The stale `F1`
selection is unreachable because it was stored only on the disposable first
clone `K1`. This discharges PO-2 and PO-3.

## Preservation arguments

Explicit child selections are preserved. If `C.values_select` is already
non-empty before compilation, `clone(C).values_select` is also non-empty, so the
existing branch condition remains false. V1 therefore does not introduce a new
override of explicitly selected child queries, satisfying PO-4.

Outer queries without `values()` / `values_list()` are preserved. If the outer
query has an empty `values_select`, the same branch condition remains false and
the child clone compiles with the same selected columns the original child
would have used.

Nested combined queries are isolated by the same rule. If a cloned child is
itself combined, its `as_sql()` calls `get_combinator_sql()` again, and that
method also constructs its child compilers from clones. This discharges PO-5.

The public API is unchanged. V1 changes neither method signatures nor queryset
construction. It only changes the identity of the internal `Query` object owned
by each child compiler.

## Formal artifacts and commands

The abstract K-style semantics and claims are in:

- `fvk/mini-django-query.k`
- `fvk/combinator-values-spec.k`

Commands to run in an environment with K installed:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/combinator-values-spec.k
kprove fvk/combinator-values-spec.k
```

Expected result if machine-checked: `#Top`.

## Test policy

No tests were run or edited. The proof suggests adding or keeping coverage for:

- repeated `values_list()` calls on the same combined queryset with different
  field lists;
- repeated `values()` calls with different field lists;
- a child query that already has an explicit values selection, to preserve
  PO-4;
- nested combined queries, to exercise PO-5.

Because the proof is constructed, not machine-checked, no test removal is
recommended here.
