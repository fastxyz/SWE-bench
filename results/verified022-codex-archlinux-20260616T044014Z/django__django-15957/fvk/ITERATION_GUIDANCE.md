# FVK Iteration Guidance

Status: guidance from constructed proof; no commands or tests were run.

## Code Decisions

1. Keep the V1 row-number rewrite for multi-valued prefetches.
   - Justification: FINDINGS F1, F5, F6 and PO1, PO2, PO3, PO6.

2. Keep the explicit `NotSupportedError` for sliced prefetches on backends
   without window support.
   - Justification: FINDINGS F3 and PO5. Python-side slicing after fetching all
     related rows contradicts the issue's performance intent.

3. Add the V2 primary-key ordering fallback for unordered sliced querysets.
   - Justification: FINDINGS F2 and PO4. The public example uses `all()[:3]`;
     unordered querysets have no promised result order, and Oracle requires
     `ORDER BY` in `ROW_NUMBER()`.

4. Leave single-valued prefetch relation handling unchanged.
   - Justification: FINDINGS F4 and PO8. The current public intent is bounded
     collections per parent. Single-valued sliced prefetch semantics need a
     separate product decision.

## Recommended Manual Review

- Inspect generated SQL on each supported backend family once an execution
  environment exists, especially Oracle and MySQL.
- Confirm that the resolved queryset ordering used for `ROW_NUMBER()` matches
  Django's normal slice ordering for explicit `order_by()` and model
  `Meta.ordering`.
- Confirm that many-to-many sticky filtering still reuses joins as intended.
- Confirm that generic relation prefetch partitions by both content type and
  object id when object ids overlap.

## Recommended Tests To Add

Do not edit tests in this benchmark. In the upstream suite, add or keep tests
covering:

- reverse many-to-one sliced prefetch with `to_attr`;
- reverse many-to-one sliced prefetch without `to_attr`;
- many-to-many sliced prefetch in both directions;
- reverse generic relation sliced prefetch;
- offset slices such as `[1:3]` and open upper-bound slices such as `[2:]`;
- unordered sliced queryset behavior;
- backend feature flag path where `supports_over_clause` is false.

## Machine Check To Run Later

Run only when K tooling is available:

```sh
kompile fvk/mini-django-prefetch.k --backend haskell
kast --backend haskell fvk/django-prefetch-spec.k
kprove fvk/django-prefetch-spec.k
```

Until those commands return `#Top`, treat the proof as constructed, not
machine-checked, and do not remove tests based on it.

## Residual Risks

- The formal model abstracts Django's SQL compiler and database execution. It
  verifies the shape of the queryset transformation, not vendor SQL text.
- Termination is not separately proved, though the helper has no unbounded loop
  or recursion.
- The single-valued relation scope decision should be revisited if future public
  requirements ask sliced custom querysets to work there too.
