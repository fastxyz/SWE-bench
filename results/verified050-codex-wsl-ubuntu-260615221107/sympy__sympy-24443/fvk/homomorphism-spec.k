requires "mini-homomorphism.k"

module HOMOMORPHISM-SPEC
  imports MINI-HOMOMORPHISM

  // SPEC-PROVENANCE:
  // - from_prompt: "When r[i] is an inverted generator, the in gens test fails."
  //   => relator evaluation must not depend on membership of the inverse
  //      free-group letter in the positive presentation-generator list.
  // - from_code: PermutationGroup.presentation constructs presentation
  //   generator symbols positionally from domain.generators.
  // - from_code: homomorphism completes images for every domain generator.
  claim eval(.Rel, P:PMap, I:IMap, id) => id

  // SPEC-PROVENANCE:
  // - from_prompt: "The given images do not define a homomorphism" is the
  //   reported false rejection for the D3 identity map.
  // - obligation: each relator syllable (sym, power), including negative power,
  //   evaluates through lookupI(images, lookupP(gen_to_s, sym)) ^ power.
  claim eval((SYM:Sym, POW:Int) REST:Relator, P:PMap, I:IMap, W:Elem)
    => eval(REST, P, I, W * (lookupI(I, lookupP(P, SYM)) ^ POW))
endmodule
