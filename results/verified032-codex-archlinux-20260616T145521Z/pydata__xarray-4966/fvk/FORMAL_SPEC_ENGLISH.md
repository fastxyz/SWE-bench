# Formal Spec English

Status: paraphrase of `fvk/unsigned-integer-coder-spec.k`; constructed, not
machine-checked.

## Claims

CLAIM-ABSENT-UNSIGNED:
If `_Unsigned` is absent, decoding terminates with the same dtype kind, values,
fill value, attrs marker absence, encoding marker absence, and warning state.

CLAIM-SIGNED-STRING-TRUE:
For signed integer data and marker `"true"`, decoding terminates with unsigned
integer dtype of the same itemsize, values cast to that unsigned dtype, fill
value cast to that unsigned dtype, `_Unsigned` removed from attrs and recorded
in encoding, and no warning.

CLAIM-SIGNED-BOOL-TRUE:
For signed integer data and marker `True`, decoding has the same result as
CLAIM-SIGNED-STRING-TRUE, with `True` recorded in encoding.

CLAIM-UNSIGNED-STRING-FALSE:
For unsigned integer data and marker `"false"`, decoding terminates with signed
integer dtype of the same itemsize, values cast to that signed dtype, fill value
cast to that signed dtype, `_Unsigned` removed from attrs and recorded in
encoding, and no warning.

CLAIM-UNSIGNED-BOOL-FALSE:
For unsigned integer data and marker `False`, decoding has the same result as
CLAIM-UNSIGNED-STRING-FALSE, with `False` recorded in encoding.

CLAIM-INTEGER-NOOP:
For integer data where the accepted marker does not request a change in
signedness, decoding moves `_Unsigned` to encoding but keeps dtype, values, fill
value, and warnings unchanged.

CLAIM-NONINTEGER-WARN:
For non-integer data with any `_Unsigned` marker, decoding moves `_Unsigned` to
encoding, keeps dtype, values, and fill value unchanged, and emits the
serialization warning.

## Cast Functions

`castValues(targetKind, itemsize, values)` applies the same value conversion as
NumPy dtype casting to every element. For one-byte unsigned-to-signed conversion,
`128` maps to `-128` and `255` maps to `-1`.

`castFill(targetKind, itemsize, fill)` applies the same conversion to
`_FillValue` when present and leaves absent fill values absent.
