# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

Reason:

F-001 and F-002 identify the reported bug and the exact lookup integration path.
PO-1 through PO-6 are discharged by the current V1 source. The only unresolved
point, F-003/PO-7, concerns exact subclass preservation and is not sufficiently
specified by the allowed public evidence to justify a broader code change.

## Suggested Tests To Add Outside This Task

Do not edit test files in this benchmark task. For a normal development pass,
the following tests would cover the public issue and residual risk:

1. A direct unit test for `resolve_lookup_value([plain_value], ...)` returning a
   list.
2. A direct unit test for `resolve_lookup_value((plain_value,), ...)` returning a
   tuple.
3. A direct unit test for list and tuple values containing expression elements,
   asserting constructor preservation and element resolution.
4. An ORM exact lookup test using a type-sensitive custom field or pickled-value
   field where stored list and stored tuple values compare differently.
5. If the project chooses exact subclass preservation, explicit tests for list
   subclasses and tuple subclasses, including namedtuple behavior.

## Suggested Tests To Keep

Keep integration and backend tests that exercise:

- lookup construction through `Query.build_filter()`;
- custom field `get_prep_value()` / `get_db_prep_value()` behavior;
- exact lookup handling of `None`, querysets, and backend-specific RHS handling;
- any subclass behavior until F-003 is clarified and formally covered.

## Machine-Check Commands

These commands were not executed in this environment:

```sh
kompile fvk/mini-python-resolve-lookup.k --backend haskell
kast --backend haskell fvk/resolve-lookup-value-spec.k
kprove fvk/resolve-lookup-value-spec.k
```

Expected successful `kprove` result after the K artifacts are made executable in
an environment with K installed: `#Top`.

## Next Intent Question

Should `resolve_lookup_value()` preserve exact concrete subclasses of list and
tuple, or is preserving the built-in list/tuple categories sufficient for the
public ORM lookup contract?

