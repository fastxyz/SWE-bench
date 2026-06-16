requires "mini-ruff-logical-lines.k"

module DEFINITION-STATE-SPEC
  imports MINI-RUFF-LOGICAL-LINES
  imports BOOL
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "False positive of E252" on `type MyType = Annotated[...]`
  //   => keyword-argument `=` inside the alias value must not enter the E252
  //   missing-whitespace branch merely because the value is subscripted.
  // - from_code: `whitespace_around_named_parameter_equals` selects the E252
  //   branch using `definition_state.in_type_params()` or an annotated function
  //   parameter at paren depth 1.
  claim
    isE252MissingBranch(
      scanState(
        notInDefinition,
        typeTok, nameTok, equalTok, nameTok, lsqbTok, newlineTok,
        nameTok, commaTok, nameTok, lparTok, nameTok, .Tokens
      ),
      2,
      false
    )
    => false

  // SPEC-PROVENANCE:
  // - from_prompt: same reproducer, including the right-hand-side `Annotated[`.
  // - from_code: V1 adds the transition on the alias assignment `=`.
  // - obligation: the `[` after the alias assignment is part of the alias value,
  //   not the opening bracket of type parameters.
  claim
    scanState(
      notInDefinition,
      typeTok, nameTok, equalTok, nameTok, lsqbTok, .Tokens
    )
    => inTypeAlias(typeParamsEnded)

  // SPEC-PROVENANCE:
  // - from_public_test: `pep_696_bad[A=int, ...]` fixture expects E25-family
  //   diagnostics for actual type-parameter defaults.
  // - from_code: type-parameter `[` before the alias assignment remains the
  //   start of the type-parameter window.
  claim
    isE252MissingBranch(
      scanState(notInDefinition, typeTok, nameTok, lsqbTok, nameTok, .Tokens),
      1,
      false
    )
    => true

  // SPEC-PROVENANCE:
  // - from_code: `inner_square_brackets` is used to avoid ending type-parameter
  //   state on nested brackets inside a type-parameter default or bound.
  // - frame condition: V1 must not weaken nested-bracket handling.
  claim
    scanState(
      notInDefinition,
      typeTok, nameTok, lsqbTok, nameTok, equalTok, nameTok,
      lsqbTok, nameTok, rsqbTok, rsqbTok, .Tokens
    )
    => inTypeAlias(typeParamsEnded)

  // SPEC-PROVENANCE:
  // - from_code docs: E252 is for annotated function keyword parameters.
  // - frame condition: V1 must not change the annotated-function E252 path.
  claim
    isE252MissingBranch(
      scanState(notInDefinition, defTok, nameTok, lparTok, nameTok, colonTok, nameTok, .Tokens),
      1,
      true
    )
    => true
endmodule
