# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

Keep V1 unchanged.

Reason:

- Finding F-001 identifies the real defect as compiler-time mutation of child
  queries stored in `combined_queries`.
- PO-2 and PO-3 show that V1 removes that mutation from the original child
  query by compiling a clone.
- Finding F-002 and PO-1 show that V1 still applies the outer selected column
  list during the current compilation.
- Finding F-003 and PO-4 show no public API or compatibility issue.

## Recommended future tests

Do not edit tests in this task. In a normal Django test environment, add or
keep tests for:

1. `qs.union(qs).values_list('name', 'order')` followed by
   `qs.union(qs).values_list('order')`, expecting the second query to return a
   one-column tuple.
2. The same repeated-evaluation shape using `values()`.
3. A combined query whose child already has an explicit `values_select`, to
   ensure V1 does not override it.
4. Nested combined queries where an inner combined child also receives an outer
   selected field list.

## Machine-check follow-up

Run these commands only in an environment where K tooling is available:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/combinator-values-spec.k
kprove fvk/combinator-values-spec.k
```

Expected result: `#Top`.

Then run the relevant Django test suite. Until both the formal commands and the
project tests are actually run, keep the proof classified as constructed, not
machine-checked.

## Residual risks

The abstract model proves the state-isolation property for selected-column
lists. It does not prove full SQL equivalence, database backend behavior,
termination, or performance. Those are outside the issue-specific intent and
should remain covered by existing integration tests.
