# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO1 - MatrixSymbol metadata

For any `MatrixSymbol` `M` with shape `(d0, ..., dn)`, when no expression-derived
array entry overrides it, `_get_input_arg_metadata(M, array_symbols)` returns
`{'dimensions': [(0, d0 - 1), ..., (0, dn - 1)]}`.

Evidence: `codegen.py` lines 567-578.

Discharge: case split in `fvk/codegen-spec.k` claim `METADATA-MATRIX`.

## PO2 - Existing array-symbol metadata

For any symbol `S` present in `array_symbols` with shaped array `A`,
`_get_input_arg_metadata(S, array_symbols)` returns dimensions derived from
`A.shape`.

Evidence: `codegen.py` lines 567-570 and 577-578.

Discharge: claim `METADATA-KNOWN-ARRAY`.

## PO3 - Scalar metadata frame

For any symbol that is not present in `array_symbols` and is not a
`MatrixSymbol`, `_get_input_arg_metadata` returns `{}`.

Evidence: `codegen.py` lines 567-575.

Discharge: claim `METADATA-SCALAR`.

## PO4 - Redundant argument construction

In `CodeGen.routine`, if a requested explicit argument is missing from
`name_arg_dict`, the synthesized `InputArgument` must be constructed with the
metadata from PO1-PO3.

Evidence: `codegen.py` lines 742-750.

Discharge: claims `ROUTINE-UNUSED-MATRIX`,
`ROUTINE-UNUSED-KNOWN-ARRAY`, and `ROUTINE-UNUSED-SCALAR`.

## PO5 - Existing argument preservation

In `CodeGen.routine`, if a requested explicit argument is present in
`name_arg_dict`, the existing argument object is reused. This preserves existing
expression-derived input metadata and output/inout argument classifications.

Evidence: `codegen.py` lines 742-747.

Discharge: claim `ROUTINE-EXISTING-ARG`.

## PO6 - C/Cython consumer propagation

If an argument has non-empty dimensions, C code generation emits a pointer
parameter, Cython exposes an ndarray argument, and the call passes the array data
pointer.

Evidence:

- `codegen.py` lines 918-926.
- `autowrap.py` lines 439-463.

Discharge: claims `C-PROTOTYPE-ARRAY`, `CYTHON-PROTOTYPE-ARRAY`, and
`CYTHON-CALL-ARRAY`.

## PO7 - Shaped IndexedBase preservation

When an explicit `IndexedBase` carries shape information before normalization to
its label symbol, `CodeGen.routine` records that shaped object in
`array_symbols`, allowing the redundant argument path to derive dimensions.

Evidence: `codegen.py` lines 724-731 and 748-750.

Discharge: claim `ROUTINE-UNUSED-KNOWN-ARRAY`.

## PO8 - Scope of language-specific builders

The proof only claims the C/Cython path that uses base `CodeGen.routine`.
Specialized `JuliaCodeGen`, `OctaveCodeGen`, and `RustCodeGen` routine builders
are outside the current public issue unless future intent expands the contract
to all codegen languages.

Evidence: public issue names autowrap with Cython backend and the bad generated
C signature.

Discharge: scope check in `SPEC_AUDIT.md` and `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO9 - Honesty gate

No test removal or machine-checked proof claim may be made because no K, Python,
or test execution is allowed.

Evidence: task constraints and FVK verify instructions.

Discharge: `PROOF.md` command section and `ITERATION_GUIDANCE.md`.

