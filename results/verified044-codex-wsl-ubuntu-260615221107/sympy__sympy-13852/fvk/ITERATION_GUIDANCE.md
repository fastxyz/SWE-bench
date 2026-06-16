# Iteration Guidance

## Decision

V1 was mostly correct against the public intent, but FVK found one audit-derived source safety issue. V2 keeps V1's two intended behavior changes and adds a narrow `lerchphi` compatibility fix.

## Applied in V2

G-001: Keep `polylog(2, S.Half)` on the construction path. This is required by F-001 and PO-001.

G-002: Keep `polylog(1, z)` expansion as `-log(1 - z)`. This is required by F-002 and PO-002.

G-003: Change the `lerchphi` rational-`a` polylog contributor from a direct private `_eval_expand_func` call to `expand_func(..., deep=False)`. This is required by F-003 and PO-003.

## Not Applied

G-004: Do not broaden automatic evaluation to all symbolic order `0`, order `1`, or negative integer identities. F-005 and PO-004 distinguish the issue's concrete construction-path value from documented opt-in symbolic expansions.

G-005: Do not edit tests. F-004 marks stale tests/comments as SUSPECT, but PO-005 and the benchmark instructions forbid test-file edits.

G-006: Do not run tests or K tooling. F-006 and PO-005 require recording commands and reasoning about expected outcomes instead.

## Next Human Review Points

Review whether the project wants more named dilogarithm constants beyond `Li_2(1/2)`. FVK did not derive another construction-path member from the public issue and local docs.

When tests are allowed, update the stale `polylog(1, z)` expected value and the Wester XFAIL around `polylog(2, 1/2)`.
