# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Required behavior

1. A signed integer variable with `_Unsigned` marked true must be decoded as the
   corresponding unsigned integer dtype of the same itemsize.

2. An unsigned integer variable with `_Unsigned` marked false must be decoded as
   the corresponding signed integer dtype of the same itemsize. This is the
   OPeNDAP/pydap case described in the issue.

3. Byte values must be reinterpreted through the target dtype representation:
   for one-byte data, unsigned `128` and `255` become signed `-128` and `-1`,
   while signed `-128` and `-1` become unsigned `128` and `255`.

4. `_FillValue`, when present, must be converted to the same target dtype as the
   data before CF masking runs.

5. `_Unsigned` handling belongs in `UnsignedIntegerCoder.decode`, which runs
   before `CFMaskCoder` and `CFScaleOffsetCoder` when `mask_and_scale=True`.

6. The accepted explicit markers are the existing string convention values
   `"true"` and `"false"` plus the explicit Python boolean values `True` and
   `False` named by the issue prose. Arbitrary truthy or falsy values are not
   accepted.

7. Non-integer data with `_Unsigned` remains non-convertible and should continue
   to emit the existing `SerializationWarning`.

8. The change must not alter public signatures, backend entrypoint APIs,
   dimensions, non-`_Unsigned` attributes, or unrelated encodings.

## Observed behavior to check

V1 handled string `"false"` on unsigned integer data but did not handle boolean
`False`. For input `dtype.kind == "u"`, `_Unsigned is False`, and byte values
`[128, 255]`, V1 left values unsigned instead of producing `[-128, -1]`.
