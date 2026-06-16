// Constructed, not machine-checked.

requires "mini-sympy-product.k"

module PRODUCT-ADD-SPEC
  imports MINI-SYMPY-PRODUCT
  imports BOOL
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: product of a sum is not the sum of products.
  // - from_docs: unevaluated Product is the fallback when the product cannot be computed.
  claim <k> addProduct(P:EvalRes, number) => none </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: if denominator product cannot be computed, no sound quotient is available.
  claim <k> addProduct(P:EvalRes, none) => none </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported q-exponential product still has an unevaluable additive numerator
  //   after denominator clearing.
  claim <k> addProduct(none, Q:EvalRes) => none </k>
    requires notBool isNumber(Q)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: rational products such as 1 + 1/n must still evaluate by
  //   product(numerator) / product(denominator) when both pieces are computable.
  claim <k> addProduct(P:EvalRes, Q:EvalRes) => quotient(P, Q) </k>
    requires notBool isNumber(Q) andBool notBool (P ==K none)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "If it cannot compute the product, it returns an unevaluated Product object."
  claim <k> productDoit(none) => unevaluated </k> [all-path]
endmodule

