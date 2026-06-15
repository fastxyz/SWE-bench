# Iteration Guidance

Status: constructed for FVK audit, not machine-checked.

## Code Decision

Keep V1 unchanged.

Reason: `fvk/FINDINGS.md` has no open code-bug finding after V1, and
`fvk/PROOF_OBLIGATIONS.md` PO-001 through PO-007 are discharged by the current
source plus the constructed proof.

## Recommended Tests for a Conventional Test Pass

Do not edit tests in this task. If tests are added later, useful regression
points are:

- patch `django.utils.http.datetime.datetime.utcnow().year` to `2018` and
  assert RFC850 year `69` expands to `1969`;
- with the same current year, assert year `68` does not roll back;
- assert the exact 50-year boundary does not roll back;
- include a UTC-boundary case to ensure local time is not used;
- preserve existing RFC1123/RFC850/asctime 1994 parsing coverage.

## Recommended Machine Check

When K tooling exists, run:

```sh
cd fvk
kompile mini-http-date.k --backend haskell
kast --backend haskell http-date-spec.k
kprove http-date-spec.k
```

Treat the proof as machine-verified only if `kprove` returns `#Top`.

## Residual Risks

The formal core proves the arithmetic year-normalization slice, not a complete
Python semantics for regexes, `datetime`, or `calendar.timegm()`. That is an
intentional abstraction because V1 only changed the arithmetic slice, and the
abstraction preserves the issue's pass/fail discriminator.

Termination is not separately proved. The audited code path has no loop or
recursion, so this is not an actionable risk for this fix.

