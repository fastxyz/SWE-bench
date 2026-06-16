# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decisions

I kept the V1 source fix unchanged. FINDINGS F-001 identifies the pre-V1 bug as
the inverted `HPacker` top/bottom branch table, and F-002 confirms that V1
discharges the intended edge equations. The relevant proof obligations are
PO-002 for bottom alignment and PO-003 for top alignment.

I did not add a migration flag, temporary uppercase alignment values, or new
packer classes. FINDINGS F-004 rejects those alternatives for this targeted
repair because PO-005 shows the diff is limited to the directional branch
membership and PO-006 shows the formal claims match public intent rather than
legacy behavior.

I did not add a `VPacker` compatibility shim for `align="top"` or
`align="bottom"`. FINDINGS F-005 records that those aliases are ambiguous for a
vertical packer's horizontal cross-axis and that the source call-site audit found
no in-repository dependency on them. PO-004 confirms the public-hint-supported
`VPacker(align="left")` and `VPacker(align="right")` behavior remains intact,
and PO-005 confirms public signatures and accepted alignment strings are
unchanged.

## Artifacts Added

The five requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the supporting FVK adequacy and formal-core files required by the
method docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-offsetbox.k`
- `fvk/offsetbox-align-spec.k`

## Verification Scope

The constructed proof models the property-carrying branch table and edge
geometry for `_get_aligned_offsets`. It proves the axis changed by V1: bottom
alignment gives `offset - descent = 0`, and top alignment gives
`offset - descent + height = container_height`. It does not claim full Python,
renderer, image, termination, or performance verification.

PO-007 records the machine-check boundary. `fvk/PROOF.md` lists the `kompile`,
`kast`, and `kprove` commands that would be run later, but this task forbids
running them.
