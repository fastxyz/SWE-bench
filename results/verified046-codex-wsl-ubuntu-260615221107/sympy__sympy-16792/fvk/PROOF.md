# PROOF

Status: constructed, not machine-checked.

## What Is Proved

For the C/Cython autowrap path, if a caller supplies an explicit unused
`MatrixSymbol` argument in `argument_sequence`, V1 constructs the corresponding
`InputArgument` with dimensions derived from the `MatrixSymbol` shape. Therefore
the generated C prototype treats it as a pointer argument and the Cython wrapper
treats it as a NumPy ndarray whose data pointer is passed to C.

This is a partial-correctness proof over the modeled code-generation path. It
does not prove termination, and it was not checked by K tooling.

## Formal Artifacts

- Semantics: `fvk/mini-codegen.k`
- Claims: `fvk/codegen-spec.k`
- Human spec: `fvk/SPEC.md`
- Obligations: `fvk/PROOF_OBLIGATIONS.md`

## Constructed Proof Sketch

1. Metadata helper.

   The helper has three relevant branches. If `array_symbols` contains the
   symbol, the helper selects that array and returns one `(0, dim - 1)` pair per
   shape dimension. If not, but the symbol is a `MatrixSymbol`, the helper uses
   the `MatrixSymbol` itself as the shaped array and returns the same dimension
   form. Otherwise no array exists and the helper returns `{}`.

   These branches discharge PO1, PO2, and PO3.

2. Redundant argument construction.

   `CodeGen.routine` builds `name_arg_dict` from already-known arguments. During
   the explicit `argument_sequence` pass, an existing symbol reuses the existing
   argument object. A missing symbol calls `_get_input_arg_metadata` and then
   constructs `InputArgument(symbol, **metadata)`.

   For the issue input `MatrixSymbol('x', 2, 1)`, the symbol is absent from the
   expression-derived `name_arg_dict`, so the missing-symbol branch is taken.
   By PO1, metadata is `{'dimensions': [(0, 1), (0, 0)]}`. The synthesized
   argument therefore has non-empty dimensions.

   These branches discharge PO4, PO5, and PO7.

3. C and Cython consumers.

   `CCodeGen.get_prototype` emits `*name` whenever `arg.dimensions` is truthy.
   The synthesized MatrixSymbol argument from step 2 has dimensions, so the C
   prototype is `double *x`, not `double x`.

   `CythonCodeWrapper._prototype_arg` emits an ndarray argument whenever
   `arg.dimensions` is truthy, and `_call_arg` passes `<double*> x.data` for the
   C call. Thus the wrapper no longer tries to convert the ndarray to a scalar
   C argument.

   These consumers discharge PO6.

4. Frame conditions.

   Scalar redundant arguments are not in `array_symbols` and are not
   `MatrixSymbol`, so they still receive `{}` metadata and remain scalar.
   Existing expression-derived arguments are found in `name_arg_dict` and reused
   unchanged. Missing required arguments are still checked before redundant
   argument synthesis.

   These facts discharge PO3 and PO5.

## Adequacy Check

The mini-K model keeps the distinguishing property under test: `noDims` versus
`dims(...)`. A failing instance maps to `input(matrix(...), noDims)` and then to
`scalarC`; the passing instance maps to `input(matrix(...), dims(...))` and then
to `pointerC`, `ndarrayPyx`, and `dataPointerCall`. The abstraction therefore
does not collapse the defect axis.

The formal English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the
intent-only obligations in `INTENT_SPEC.md`; `SPEC_AUDIT.md` marks all required
C/Cython obligations as pass.

## Machine-Check Commands Not Run

The following commands are the intended reproduction path. They were not run in
this session.

```sh
cd fvk
kompile mini-codegen.k --backend haskell
kast --backend haskell codegen-spec.k
kprove codegen-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Test Guidance

No tests were modified. Because this proof is constructed but not
machine-checked, no existing tests should be removed on the basis of this FVK
pass. Future public tests should include the issue reproducer and a scalar
redundant-argument frame test.

