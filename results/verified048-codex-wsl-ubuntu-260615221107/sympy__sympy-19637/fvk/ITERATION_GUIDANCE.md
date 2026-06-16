# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not make an additional source-code edit. The FVK audit confirms that the V1
change is the minimal repair for the public issue:

- F-001 is resolved by PO-2.
- F-002 confirms the placeholder cleanup behavior remains intact through PO-3
  and PO-5.
- F-005 confirms public compatibility through PO-6.

## Recommended Follow-Up Tests

No tests may be edited in this benchmark task, and no tests were run. If a later
developer adds public tests, the high-value cases are:

- `kernS("(2*x)/(x-1)")` does not raise `UnboundLocalError`.
- A no-placeholder parenthesized input, such as `kernS("(x)")`, delegates through
  the safe `hit == False` path.
- Existing placeholder examples like `kernS("2*(x + y)")` and `kernS("-(x + 1)")`
  still preserve the anti-distribution behavior.
- Fallback behavior for a placeholder-path `TypeError` still retries the
  un-hacked string.

## Machine-Checking Guidance

The constructed proof can be machine-checked later with:

```sh
cd fvk
kompile mini-kernS.k --backend haskell
kast --backend haskell kernS-spec.k
kprove kernS-spec.k
```

Do not remove tests based on this proof unless the commands discharge the claims
to `#Top`.

## Open Boundaries

F-003 and F-004 are intentionally left as proof-scope boundaries rather than
source changes. They concern full `sympify` semantics and total termination of
the random fresh-name loop. Neither is required to fix the public
`UnboundLocalError` issue.
