# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Marker classification

The decoder must classify only explicit markers:

- unsigned marker iff `_Unsigned == "true"` or `_Unsigned is True`;
- signed marker iff `_Unsigned == "false"` or `_Unsigned is False`.

Arbitrary truthy or falsy values must not trigger conversion.

Discharged by: source inspection of `is_unsigned` and `is_signed`; K claims
CLAIM-SIGNED-STRING-TRUE, CLAIM-SIGNED-BOOL-TRUE,
CLAIM-UNSIGNED-STRING-FALSE, and CLAIM-UNSIGNED-BOOL-FALSE.

Findings: F1.

## PO2: Opposite-signedness conversion

If data kind is signed integer and marker is unsigned, the target dtype must be
unsigned with the same itemsize. If data kind is unsigned integer and marker is
signed, the target dtype must be signed with the same itemsize.

Discharged by: `np.dtype("u%s" % data.dtype.itemsize)` and
`np.dtype("i%s" % data.dtype.itemsize)` in source; K target-kind claims.

Findings: F1, F2.

## PO3: Value and fill conversion use the same target dtype

Data values and `_FillValue` must be converted with the same target dtype so
later masking compares values in the same representation.

Discharged by: source uses `lazy_elemwise_func(..., new_dtype)` for data and
`new_dtype.type(attrs["_FillValue"])` for fill; K `castValues` and `castFill`
postconditions.

Findings: F3.

## PO4: Decoder ordering before mask and scale

The signedness conversion must occur before `CFMaskCoder` and
`CFScaleOffsetCoder`.

Discharged by: `decode_cf_variable` coder order:
`UnsignedIntegerCoder`, `CFMaskCoder`, `CFScaleOffsetCoder`.

Findings: F2, F3.

## PO5: Non-integer warning behavior

Data whose dtype kind is not signed or unsigned integer must not be converted
and must continue to emit the existing serialization warning.

Discharged by: source `else` branch after `data.dtype.kind in ("i", "u")`; K
CLAIM-NONINTEGER-WARN.

Findings: F4.

## PO6: Frame preservation

Dims, shape, non-`_Unsigned` attrs, unrelated encoding fields, and public return
shape must be preserved.

Discharged by: source only rewrites `data`, `_FillValue`, and moves `_Unsigned`
from attrs to encoding; no signature or return shape change.

Findings: none.

## PO7: Adequacy

Every nontrivial formal claim must trace to public intent rather than candidate
behavior.

Discharged by: `fvk/SPEC_AUDIT.md`; V1 failed this obligation for boolean
`False`, and V2 repairs it.

Findings: F1.

## PO8: Machine-checking honesty

The proof must be labeled constructed, not machine-checked, and must include the
commands a human could run later.

Discharged by: `fvk/PROOF.md`.

Findings: F5.
