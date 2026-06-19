# FVK Notes

## Decisions

V1 was not kept unchanged. Finding F3 and proof obligation PO3 showed that the
nonzero adjusted-exponent threshold did not cover zero-valued Decimals with
large exponents. I added `number.is_zero()` to the cutoff shortcut so zero
always takes the fixed-zero path when `decimal_pos` is non-negative.

Finding F4 and proof obligations PO5/PO6 showed that V1's shortcut was broader
than necessary: it ran before the existing fixed-format path even when the
200-digit cutoff was not active. I moved the shortcut inside the cutoff branch
so ordinary fixed formatting remains unchanged.

The same F4/PO6 compatibility audit also identified Decimal subclass formatting
as public behavior. In the cutoff shortcut, V2 now attempts to format a
same-class zero surrogate for Decimal subclasses. If that construction is not
supported, it falls back to the plain zero string rather than raising from the
new compatibility path.

## No Test Execution

No tests, Python snippets, `kompile`, or `kprove` commands were run. The FVK
proof and commands are constructed artifacts only, as required by the task.

## Artifact Trace

The source change is justified by:

- F1/PO1: fixes the public `Decimal('1e-200')`, `decimal_pos=2` symptom.
- F2/PO2: treats stale exponent expectations for smaller-than-displayable
  values as suspect legacy behavior.
- F3/PO3: covers zero-valued Decimal exponent edge cases missed by V1.
- F4/PO5/PO6: narrows the shortcut and preserves Decimal subclass behavior
  where feasible.
- F5/PO7/PO8: limits the formal claim to the cutoff decision and fixed-zero
  output shape, with machine checking deferred.
