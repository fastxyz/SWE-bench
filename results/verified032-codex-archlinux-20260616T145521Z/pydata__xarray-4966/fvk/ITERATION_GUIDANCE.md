# Iteration Guidance

Status: FVK repair pass complete.

## Code Outcome

V1 did not fully satisfy the public intent because it only accepted string
`"false"` for the OPeNDAP signed-byte marker. V2 updates
`UnsignedIntegerCoder.decode` to accept explicit boolean `False` and explicit
boolean `True` in addition to the existing string markers.

No backend code, tests, or public API signatures should be changed for this
issue.

## Next Conventional Tests

Add focused tests outside this task's constraints for:

- `np.uint8([128, 255])` with `_Unsigned="false"`;
- `np.uint8([128, 255])` with `_Unsigned=False`;
- fill-value recasting before masking;
- non-integer `_Unsigned` warning preservation.

## Machine-Check Follow-Up

Run the commands listed in `fvk/PROOF.md` in an environment with K installed.
Until `kprove` returns `#Top`, treat proof-based test removal as unsupported.

## Open Questions

No user clarification is needed for the current repair. Future work could decide
whether encode should also accept boolean `_Unsigned` markers, but that is not
required by this pydap decode issue and was intentionally left unchanged.
