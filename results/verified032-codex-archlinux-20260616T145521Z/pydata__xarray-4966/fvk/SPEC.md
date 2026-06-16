# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

`repo/xarray/coding/variables.py::UnsignedIntegerCoder.decode`

This audit covers the `_Unsigned` decoding branch used by
`repo/xarray/conventions.py::decode_cf_variable` when `mask_and_scale=True`.

## Intent Ledger Summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1 and E8 require the existing netCDF convention: signed integer data plus
  `_Unsigned="true"` decodes as unsigned data of the same itemsize.
- E2, E3, and E4 require the OPeNDAP/pydap mirror case: unsigned integer data
  plus `_Unsigned` false decodes as signed data of the same itemsize, including
  one-byte values `128 -> -128` and `255 -> -1`.
- E5, E6, E7, and E10 locate the fix in the shared CF variable decoder before
  masking/scaling rather than in the pydap backend.
- E9 makes boolean marker handling a candidate-derived ambiguity in V1. Because
  the issue explicitly writes `unsigned == False`, V2 treats explicit booleans
  as accepted decode markers while avoiding arbitrary truthy/falsy values.

## Domain

The formalized domain is a `Variable`-like state with:

- a data dtype kind `i`, `u`, or other;
- a positive integer dtype itemsize;
- an optional `_Unsigned` marker;
- a finite list of integer encoded values;
- an optional `_FillValue`;
- attrs and encoding dictionaries.

Accepted decode markers:

- unsigned marker: `"true"` or `True`;
- signed marker: `"false"` or `False`.

Other marker values are in-domain but do not request a conversion.

## Postconditions

P1. If `_Unsigned` is absent, `UnsignedIntegerCoder.decode` leaves data,
attrs, and encoding unchanged except for ordinary object copying.

P2. If `_Unsigned` is present, it is moved from `attrs` to `encoding`.

P3. If data dtype kind is signed integer and the marker is unsigned, data is
converted lazily to unsigned dtype `u{itemsize}`. `_FillValue`, if present, is
converted to the same unsigned dtype.

P4. If data dtype kind is unsigned integer and the marker is signed, data is
converted lazily to signed dtype `i{itemsize}`. `_FillValue`, if present, is
converted to the same signed dtype.

P5. Integer data whose marker already matches its signedness, or whose marker is
not one of the accepted explicit markers, is not converted.

P6. Non-integer data with `_Unsigned` is not converted and emits the existing
`SerializationWarning`.

P7. Dims, shape, non-`_Unsigned` attrs, unrelated encoding fields, and lazy
evaluation structure are preserved. The only value transformation is the dtype
cast in P3 or P4.

## Formal Artifacts

- `fvk/mini-unsigned-coder.k` models the relevant decoder state and transitions.
- `fvk/unsigned-integer-coder-spec.k` states claims for absent markers, string
  and boolean signedness conversions, no-op integer markers, and non-integer
  warnings.

The K model abstracts Python dictionaries and xarray `Variable` objects into
cells for the fields relevant to the issue. This abstraction is property-complete
for the audited behavior because it preserves the axes the defect manipulates:
dtype kind, itemsize, marker value, data values, fill value, warning emission,
and the attrs-to-encoding move.

## V2 Code Decision

V1 already fixed string `_Unsigned="false"` on unsigned integer data. FVK Finding
F1 showed that V1 did not cover explicit boolean `False` despite public evidence
E3. V2 therefore adds explicit boolean marker recognition in decode:

- `unsigned == "true" or unsigned is True`;
- `unsigned == "false" or unsigned is False`.

The change is intentionally limited to decode and does not accept generic
truthiness or falsiness.
