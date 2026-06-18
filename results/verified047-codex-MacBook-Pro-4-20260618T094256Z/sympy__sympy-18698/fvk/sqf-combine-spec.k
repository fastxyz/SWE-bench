requires "mini-sqf-combine.k"

module SQF-COMBINE-SPEC
  imports MINI-SQF-COMBINE

  // SPEC-PROVENANCE:
  // - from_prompt: "The two factors of multiplicity 3 are combined as they should be."
  //   => factors with the same generator tuple and multiplicity are multiplied into one factor.
  // - from_prompt: "It should scan the generic factor list and combine factors of same multiplicity"
  //   => post-processing occurs after generic factor-list construction.
  // - from_code: _combine_factors groups by (factor.gens, exp) and multiplies the stored Poly values.
  claim
    <k> combineFactors(
          fac(atom(1, 11), 1) ;;
          fac(atom(1, 21), 2) ;;
          fac(atom(1, 31), 3) ;;
          fac(atom(1, 32), 3) ;;
          .Factors
        )
      => fac(atom(1, 11), 1) ;;
         fac(atom(1, 21), 2) ;;
         fac(pprod(atom(1, 31), atom(1, 32)), 3) ;;
         .Factors
      ...
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the "one factor for each power" statement is not limited to multiplicity 3.
  // - from_default_domain: a square-free decomposition groups every equal multiplicity, including 1.
  // - from_code: V1 applies the same helper to all exponents.
  claim
    <k> combineFactors(
          fac(atom(1, 41), 1) ;;
          fac(atom(1, 42), 1) ;;
          .Factors
        )
      => fac(pprod(atom(1, 41), atom(1, 42)), 1) ;;
         .Factors
      ...
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: repo/sympy/polys/tests/test_polytools.py keeps
  //   sqf_list(x*(x + y)) as two symbolic factors.
  // - from_prompt: multiple-generator behavior is explicitly described as ambiguous.
  // - frame condition: V1 must not combine factors whose generator tuples differ.
  claim
    <k> combineFactors(
          fac(atom(1, 51), 1) ;;
          fac(atom(2, 52), 1) ;;
          .Factors
        )
      => fac(atom(1, 51), 1) ;;
         fac(atom(2, 52), 1) ;;
         .Factors
      ...
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the repair target is sqf_list, not ordinary factor_list.
  // - from_code: _generic_factor_list calls _combine_factors only when method == 'sqf'.
  // - frame condition: factor_list behavior is preserved.
  claim
    <k> normalizeFactors(
          factor,
          fac(atom(1, 61), 2) ;;
          fac(atom(1, 62), 2) ;;
          .Factors
        )
      => fac(atom(1, 61), 2) ;;
         fac(atom(1, 62), 2) ;;
         .Factors
      ...
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: sqf_list should combine factors of the same multiplicity.
  // - from_code: the sqf dispatch normalizes numerator and denominator factor lists
  //   through the same helper before sorting and expression conversion.
  claim
    <k> normalizeFactors(
          sqf,
          fac(atom(1, 71), 5) ;;
          fac(atom(1, 72), 5) ;;
          .Factors
        )
      => fac(pprod(atom(1, 71), atom(1, 72)), 5) ;;
         .Factors
      ...
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the Python for-loop is modeled by the combineAcc recursion.
  // - proof-required: one semantic step consumes the head before recursive reuse.
  claim
    <k> combineAcc(F:Factor ;; REST:Factors, ACC:Factors)
      => combineAcc(REST, appendOrMul(F, ACC))
      ...
    </k>
    [all-path]
endmodule
