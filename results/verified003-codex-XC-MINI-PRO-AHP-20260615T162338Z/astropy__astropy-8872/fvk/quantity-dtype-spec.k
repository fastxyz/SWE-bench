requires "mini-quantity.k"

module QUANTITY-DTYPE-SPEC
  imports MINI-QUANTITY

  // SPEC-PROVENANCE:
  // - from_prompt: "(np.float16(1) * u.km).dtype" should not become float64.
  // - from_code: UnitBase.__rmul__ delegates numeric operands to Quantity(m, unit).
  // - obligation: the no-explicit-dtype non-Quantity branch preserves float16.
  claim <k> construct(nonQuantity, float16, noDType) => float16 </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "allow every inexact type."
  // - obligation: all inexact dtypes are preserved by default for non-Quantity input.
  claim <k> construct(nonQuantity, D:DType, noDType) => D </k>
    requires isInexact(D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: both old predicate sites must be fixed.
  // - obligation: all inexact dtypes are preserved by default when copying a Quantity.
  claim <k> construct(quantityCopy, D:DType, noDType) => D </k>
    requires isInexact(D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: explicit dtype is used when supplied.
  // - obligation: explicit dtype overrides default inference.
  claim <k> construct(nonQuantity, D:DType, someDType(explicitD)) => explicitD </k>
    [all-path]

  claim <k> construct(quantityCopy, D:DType, someDType(explicitD)) => explicitD </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: copy=False for Quantity returns the existing object/dtype.
  // - obligation: no-copy Quantity path is unchanged.
  claim <k> construct(quantityNoCopy, D:DType, noDType) => D </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: integer, bool, and object defaults are converted to float.
  // - obligation: non-inexact scalar-like defaults still produce float64.
  claim <k> construct(nonQuantity, intD, noDType) => float64 </k> [all-path]
  claim <k> construct(nonQuantity, boolD, noDType) => float64 </k> [all-path]
  claim <k> construct(nonQuantity, objectD, noDType) => float64 </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: dtype.fields exception already preserves structured dtypes.
  // - obligation: structured dtype behavior is framed unchanged.
  claim <k> construct(nonQuantity, structuredD, noDType) => structuredD </k> [all-path]
  claim <k> construct(quantityCopy, structuredD, noDType) => structuredD </k> [all-path]
endmodule
