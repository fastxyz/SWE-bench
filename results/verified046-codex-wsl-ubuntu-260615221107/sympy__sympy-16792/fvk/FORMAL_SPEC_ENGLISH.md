# FORMAL_SPEC_ENGLISH

Status: constructed, not machine-checked.

## METADATA-MATRIX

For any matrix argument with shape `(rows, cols)` and no overriding
expression-derived array entry, metadata construction returns dimensions
`[(0, rows - 1), (0, cols - 1)]`.

## METADATA-KNOWN-ARRAY

For any symbol with a known shaped array entry, metadata construction returns
dimensions from that known array's shape.

## METADATA-SCALAR

For any scalar symbol with no known shaped array entry, metadata construction
returns no dimensions.

## ROUTINE-UNUSED-MATRIX

When the explicit argument sequence contains a matrix argument that is not
already in the routine argument dictionary, the synthesized input argument has
dimensions from the matrix shape.

## ROUTINE-UNUSED-KNOWN-ARRAY

When the explicit argument sequence contains a symbol with known shaped array
metadata, the synthesized input argument has dimensions from that known shape.

## ROUTINE-UNUSED-SCALAR

When the explicit argument sequence contains a scalar symbol that is not already
in the routine argument dictionary, the synthesized input argument has no
dimensions.

## ROUTINE-EXISTING-ARG

When the explicit argument sequence names an argument already known to the
routine, the existing argument object is reused unchanged.

## C-PROTOTYPE-ARRAY

An input argument with dimensions is emitted as a C pointer parameter.

## CYTHON-PROTOTYPE-ARRAY

An input argument with dimensions is exposed in Cython as a NumPy ndarray
parameter.

## CYTHON-CALL-ARRAY

An input argument with dimensions is passed from Cython to C as the ndarray data
pointer.

