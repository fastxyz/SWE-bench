# FVK Findings

Status: findings from `/formalize` and `/verify`; proof constructed, not
machine-checked.

## F1: V1 omitted explicit boolean false marker

Classification: code bug in V1, repaired in V2.

Evidence: Public ledger E3 quotes the issue's suggested condition:
`if .kind == "u" and unsigned == False`.

Concrete input: unsigned one-byte data values `[128, 255]`, dtype kind `u`,
itemsize `1`, attrs `{"_Unsigned": False}`.

Observed in V1 by static inspection: `data.dtype.kind in ("i", "u")` is true,
but `unsigned == "false"` is false for boolean `False`; `new_dtype` remains
`None`, so values stay unsigned.

Expected: `_Unsigned=False` means unsigned OPeNDAP bytes represent signed byte
data, so values decode to `[-128, -1]`.

Resolution: V2 accepts explicit boolean `False` for the signed marker and
explicit boolean `True` for the unsigned marker in decode, without accepting
arbitrary truthy or falsy values.

Related proof obligations: PO1, PO2, PO3.

## F2: Original pydap unsigned-byte path is fixed

Classification: original code bug, repaired by V1 and retained in V2.

Evidence: Public ledger E2 and E4. The issue shows pydap returning `128.0` and
`255.0` where netCDF4 returns `-128.0` and `-1.0`.

Concrete input: unsigned one-byte data values `[128, 255]`, dtype kind `u`,
itemsize `1`, attrs `{"_Unsigned": "false"}`.

Observed before V1 by source inspection: the original decoder only accepted
`data.dtype.kind == "i"` for `_Unsigned`; unsigned data hit the warning branch
and was left uninterpreted.

Expected: values decode to signed one-byte values `[-128, -1]`.

Resolution: V2 preserves V1's unsigned-to-signed branch for string `"false"`.

Related proof obligations: PO1, PO2, PO4.

## F3: Fill value conversion is required before masking

Classification: required side condition, satisfied by V2.

Evidence: Public ledger E7 shows `UnsignedIntegerCoder` runs before
`CFMaskCoder`; the issue output includes a masked `nan`.

Concrete input: unsigned one-byte data values `[129]`, dtype kind `u`, itemsize
`1`, attrs `{"_Unsigned": "false", "_FillValue": 129}`.

Expected: data and fill both cast to signed one-byte representation, so the
later mask compares `-127` to `-127`.

Resolution: V2 casts `_FillValue` with the same `new_dtype.type(...)` used for
the data conversion.

Related proof obligations: PO3, PO4.

## F4: Non-integer warning remains intentionally outside the repair

Classification: preserved behavior.

Evidence: Public ledger E6 limits `_Unsigned` decoding to integer arrays.

Concrete input: float data with attrs `{"_Unsigned": "false"}`.

Expected: no signedness conversion; existing `SerializationWarning` remains.

Resolution: V2 only routes dtype kinds `"i"` and `"u"` through integer marker
handling. Other dtype kinds still warn.

Related proof obligations: PO5.

## F5: Proof is constructed, not machine-checked

Classification: proof capability gap due task constraints.

Evidence: User forbids running tests, Python, `kompile`, or `kprove`.

Expected: FVK artifacts include exact commands and a constructed proof, but do
not claim machine-checked `#Top`.

Resolution: `fvk/PROOF.md` lists the commands to run later and labels the proof
accordingly.

Related proof obligations: PO8.
