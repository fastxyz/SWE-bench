# FVK Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claim

For a standard ForeignKey formfield queryset `B` with unique primary keys and a
non-empty `limit_choices_to` relation `L`, V1 computes:

```
patched(B, L) = [r for r in B if exists witness . L(r, witness)]
```

and therefore does not introduce duplicate rendered choices or
`MultipleObjectsReturned` validation failures from multi-witness joins.

## Symbolic Model

Let:

- `pk(r)` be the model primary key of row `r`.
- `unique_pks(B)` mean no two rows in `B` have the same primary key.
- `witnesses(L, r)` be the finite set of joined witness rows satisfying `L` for
  `r`.
- `qualifies(L, r)` mean `witnesses(L, r)` is non-empty.

Legacy direct filtering has the duplicate-producing shape:

```
direct(B, L) = concat(repeat(r, len(witnesses(L, r))) for r in B)
```

V1 has the existence-filter shape:

```
patched(B, L) = filter(lambda r: qualifies(L, r), B)
```

This abstraction preserves the property under verification: a failing instance
`B=[A]`, `len(witnesses(L,A))=2` maps to `direct=[A,A]`, while the passing V1
instance maps to `patched=[A]`.

## Proof Sketch

PO-1, membership equivalence: V1 builds the condition
`L & Q(pk=OuterRef('pk'))` inside `base_manager.filter(...)`, then wraps that
subquery in `Exists(...)` and applies it to the original outer queryset. For an
outer row `r`, `Exists` is true exactly when at least one base row with
`pk=pk(r)` satisfies `L`. Since primary keys identify model rows in this domain,
that is equivalent to `qualifies(L, r)`.

PO-2, uniqueness: `patched(B, L)` is produced by filtering `B`; it never expands
one row into one row per witness. Filtering can remove elements but cannot add a
second copy of an element. Therefore `unique_pks(B)` implies
`unique_pks(patched(B, L))`.

PO-3, validation: `ModelChoiceField.to_python()` calls `.get()` on
`self.queryset`, and the helper rewrites that shared queryset before rendering
or validation. If submitted key `p` is present in `patched(B, L)`, PO-2 gives
exactly one row with `pk=p`. Therefore `.get(pk=p)` cannot encounter
limit-induced multiplicity. If `p` is absent, existing invalid-choice behavior
is preserved.

PO-4, no row-wide distinct dependency: V1 adds `filter(Exists(...))`. It does
not add `.distinct()` and does not require the database to compare selected
custom field values to deduplicate rows.

PO-5, input form preservation: V1 obtains the limit via
`get_limit_choices_to()` as before. If the resolved value is a dictionary, the
code converts it to `Q(**limit_choices_to)`, which matches
`QuerySet.complex_filter()`'s documented accepted dictionary input. If it is a
`Q`, it is combined directly. Empty values skip the filter, matching the
semantic no-op of an empty direct filter.

PO-6, compatibility: no public signature or consumer protocol changed.

## Constructed K Commands

These commands are recorded for a future environment with K installed. They were
not run in this task.

```sh
kompile fvk/mini-django-queryset.k --backend haskell
kast --backend haskell fvk/limit-choices-to-spec.k
kprove fvk/limit-choices-to-spec.k
```

Expected machine-check result for this abstraction: `#Top`. Until those commands
are actually run successfully, this remains a constructed proof rather than a
machine-checked result.

## Test Recommendation

Do not remove tests. Because the proof is not machine-checked and the project
tests are fixed/hidden for this task, all tests should be kept. Useful tests to
add in a normal development setting are listed in `ITERATION_GUIDANCE.md`.

## Residual Risk

The proof is partial and abstract. It proves the cardinality/membership property
of the V1 query transformation under the stated domain assumptions; it does not
prove full Django ORM SQL compilation semantics, database optimizer behavior, or
termination/performance properties.
