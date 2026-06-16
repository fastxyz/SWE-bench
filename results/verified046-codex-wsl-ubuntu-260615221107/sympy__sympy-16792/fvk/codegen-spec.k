// Claims for the sympy__sympy-16792 codegen metadata proof.
// Status: constructed, not machine-checked.

requires "mini-codegen.k"

module CODEGEN-SPEC
  imports MINI-CODEGEN

  // SPEC-PROVENANCE:
  // - from_prompt: "`x` should be `double *`, not `double`" =>
  //   MatrixSymbol arguments have dimensions even when unused.
  // - from_code: CodeGen._get_input_arg_metadata MatrixSymbol branch.
  claim <k> metadata(matrix(N:Name, shape2(R:Int, C:Int)), unknownArray)
        => dims2(R -Int 1, C -Int 1) ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: array_symbols entries are authoritative shaped arrays.
  claim <k> metadata(scalar(N:Name), knownArray(shape2(R:Int, C:Int)))
        => dims2(R -Int 1, C -Int 1) ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: scalar redundant arguments remain scalar.
  claim <k> metadata(scalar(N:Name), unknownArray) => noDims ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: explicit unused MatrixSymbol belongs to the requested
  //   signature.
  // - from_code: missing name_arg_dict branch calls metadata helper.
  claim <k> redundantArg(matrix(N:Name, shape2(R:Int, C:Int)),
                         missingArg,
                         unknownArray)
        => input(matrix(N, shape2(R, C)), dims2(R -Int 1, C -Int 1)) ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: shaped IndexedBase normalization records array_symbols entry.
  claim <k> redundantArg(indexed(N:Name, shape2(R:Int, C:Int)),
                         missingArg,
                         knownArray(shape2(R, C)))
        => input(indexed(N, shape2(R, C)), dims2(R -Int 1, C -Int 1)) ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: scalar redundant arguments stay scalar.
  claim <k> redundantArg(scalar(N:Name), missingArg, unknownArray)
        => input(scalar(N), noDims) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing arguments are reused from name_arg_dict.
  claim <k> redundantArg(A:Arg, knownArg(OBJ:ArgObj), unknownArray)
        => OBJ ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: generated C must use `double *x`.
  // - from_code: CCodeGen.get_prototype selects pointer on dimensions.
  claim <k> cPrototype(input(matrix(N:Name, shape2(R:Int, C:Int)),
                             dims2(R -Int 1, C -Int 1)))
        => pointerC ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: Cython wrapper should accept ndarray argument.
  // - from_code: CythonCodeWrapper._prototype_arg selects ndarray on dimensions.
  claim <k> cythonPrototype(input(matrix(N:Name, shape2(R:Int, C:Int)),
                                  dims2(R -Int 1, C -Int 1)))
        => ndarrayPyx ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: wrapper must pass array to pointer C parameter, not scalar.
  // - from_code: CythonCodeWrapper._call_arg selects .data pointer on dimensions.
  claim <k> cythonCall(input(matrix(N:Name, shape2(R:Int, C:Int)),
                             dims2(R -Int 1, C -Int 1)))
        => dataPointerCall ... </k>
    requires R >Int 0 andBool C >Int 0
    [all-path]
endmodule

