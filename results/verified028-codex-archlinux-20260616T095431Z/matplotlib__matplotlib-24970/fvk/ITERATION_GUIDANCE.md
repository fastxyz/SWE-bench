# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit `repo/lib/matplotlib/colors.py` beyond V1.

The FVK audit confirms that V1 directly establishes the public-intent
condition from the issue discussion: integer `xa` must be able to hold
`self.N + 2` before the special under, over, and bad indices are assigned.

## Trace to Findings and Obligations

- Keep the V1 promotion guard because F-001 and PO-001 through PO-004 show it
  removes the reported warning mechanism.
- Keep the fix as promotion rather than modulo arithmetic because F-003 and
  PO-003 show modulo wrapping would route special cases to ordinary colormap
  entries.
- Do not broaden the edit into unrelated branches because F-004 and PO-006
  show the public API and non-integer behavior are already preserved.
- Do not remove or modify tests because F-005 and PO-007 keep this proof
  constructed, not machine-checked.

## Suggested Future Work Outside This Benchmark Pass

If a normal execution environment becomes available:

1. Add or run tests for the reported empty `uint8` reproduction under warnings
   enabled.
2. Add or run tests for masked/bad values in a small integer dtype that cannot
   represent `N + 2`.
3. Run the included K skeletons with the listed `kompile` and `kprove`
   commands.

No such commands were run in this session.
