# FINDINGS

Status: constructed, not machine-checked.

## F1 - Pre-fix scalarization of unused MatrixSymbol arguments

Classification: code bug fixed by V1.

Input: `expr = 1.0`, `argument_sequence = (MatrixSymbol('x', 2, 1),)`,
`backend = 'cython'`.

Observed before V1: `CodeGen.routine` reached the redundant-argument path and
created `InputArgument(x)` with no dimensions. `CCodeGen.get_prototype` therefore
emitted `double x`, and the Cython wrapper attempted to pass a NumPy array to a
scalar argument.

Expected from public intent: `x` remains an array argument even though it is not
referenced by `expr`; the C signature uses `double *x`, and the Cython wrapper
accepts an ndarray and passes `x.data`.

V1 status: fixed. The missing `KeyError` path now calls
`_get_input_arg_metadata`, which derives dimensions directly from a
`MatrixSymbol`.

Related obligations: PO1, PO4, PO6.

## F2 - V1 scalar frame condition

Classification: no bug found.

Input: an explicit redundant scalar `Symbol` not present in the expression.

Observed in V1: `_get_input_arg_metadata` returns `{}` when the argument is not a
known shaped array and is not a `MatrixSymbol`.

Expected from public intent: scalar redundant arguments remain scalar.

V1 status: confirmed. The C prototype remains scalar for scalar explicit
arguments.

Related obligations: PO3, PO5.

## F3 - Unshaped IndexedBase is intentionally outside the array-metadata claim

Classification: underspecified intent, no code change for current issue.

Input: an explicit unused `IndexedBase('A')` with no declared shape and no
indexed occurrence in the expression.

Observed in V1: there is no expression index and no declared shape from which to
derive dimensions, so `_get_input_arg_metadata` has no array shape to encode.

Expected from public intent: the issue's concrete in-domain array argument is a
`MatrixSymbol` with declared shape. A shaped `IndexedBase` is also preserved by
V1, but an unshaped unused `IndexedBase` has insufficient public shape evidence.

V1 status: confirmed as out of scope for the current spec. Future intent could
add an explicit API for declaring unused unshaped indexed arrays, but that is not
required by the public issue.

Related obligations: PO2, PO7.

## F4 - Other language-specific routine builders are not part of this Cython proof

Classification: scope note, not a current code bug.

Input: `JuliaCodeGen.routine`, `OctaveCodeGen.routine`, or
`RustCodeGen.routine` with an unused `MatrixSymbol` in `argument_sequence`.

Observed in source: those specialized routine builders contain similar
redundant-argument construction code, but they are not used by the Cython
autowrap path in the issue. The Cython path uses `CCodeGen`, which inherits the
patched base `CodeGen.routine`.

Expected from public intent: fix the reported Cython/autowrap failure and the C
signature it generates.

V1 status: no source change. If future public intent requires identical
unused-array behavior for all codegen languages, those specialized builders
should be audited separately.

Related obligations: PO8.

## F5 - Proof honesty boundary

Classification: proof capability gap.

The FVK proof is constructed from static inspection and a mini-K model. It was
not machine-checked with `kompile` or `kprove`, and no Python/tests were run.

Expected from FVK: label the result "constructed, not machine-checked" and
condition any test-removal recommendation on a later machine check.

V1 status: satisfied. No tests are removed or modified.

Related obligations: PO9.

