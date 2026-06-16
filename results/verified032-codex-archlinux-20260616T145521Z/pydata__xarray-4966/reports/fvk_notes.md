# FVK Notes

## Source changes after V1

`repo/xarray/coding/variables.py`

V2 extends `UnsignedIntegerCoder.decode` marker recognition from string-only
checks to explicit marker checks:

- unsigned marker: `unsigned == "true" or unsigned is True`;
- signed marker: `unsigned == "false" or unsigned is False`.

This change is justified by `fvk/FINDINGS.md` F1 and proof obligations PO1 and
PO2. V1 handled `_Unsigned="false"` but not `_Unsigned=False`, even though the
issue text explicitly described the desired branch as `unsigned == False`.

The change deliberately avoids generic truthiness/falsiness. Numeric `0`/`1`,
empty strings, and other truthy/falsy values are not accepted as decode markers.
That limit follows PO1 and avoids expanding beyond the public intent.

## Decisions to keep V1 behavior

The V1 unsigned-to-signed conversion for `_Unsigned="false"` stands. It is
supported by F2 and PO2.

The V1 `_FillValue` conversion stands. It is required by F3 and PO3 because
`UnsignedIntegerCoder` runs before `CFMaskCoder`; data and fill values must be
in the same signedness representation before masking.

The non-integer warning behavior stands. F4 and PO5 require the warning to
remain for non-integer data; the original issue only makes unsigned integer data
stop warning.

The repair remains in `UnsignedIntegerCoder.decode`, not the pydap backend. This
follows public evidence ledger E5/E10 and PO4: pydap passes attributes through,
and the shared CF decoder already owns `_Unsigned` interpretation before mask
and scale.

## Verification status

The FVK proof is constructed but not machine-checked, per F5 and PO8. No tests,
Python, `kompile`, or `kprove` were run.

Artifacts written under `fvk/` include the requested `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`, plus the FVK
adequacy files and K model required by the kit documentation.
