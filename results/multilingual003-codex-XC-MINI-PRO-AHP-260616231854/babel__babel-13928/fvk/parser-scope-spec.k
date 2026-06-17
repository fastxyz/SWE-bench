requires "mini-parser-scope.k"

module PARSER-SCOPE-SPEC
  imports MINI-PARSER-SCOPE
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: reported await/yield examples are valid programs.
  // - from_hint: expected scope trace enters and exits the arrow-body expression scope
  //   before leaving the nested function parameter declaration scope.
  // - from_code: recordParameterInitializerError returns at an Expression scope
  //   boundary and raises at a ParameterDeclaration scope.
  claim <k> parseFunctionParamsWithConciseArrowDefault ; recordParamInit ; done
          => done
        </k>
        <stack> ListItem(E) REST => ListItem(E) REST </stack>
        <outcome> ok </outcome>
    [all-path, label(reported-await-yield-valid)]

  // SPEC-PROVENANCE:
  // - from_code: an actual parameter-initializer await/yield with top scope P
  //   must still raise the formal-parameter diagnostic.
  claim <k> recordParamInit ; done => done </k>
        <stack> ListItem(P) REST => ListItem(P) REST </stack>
        <outcome> ok => paramError </outcome>
    [all-path, label(parameter-error-preserved)]

  // SPEC-PROVENANCE:
  // - from_code: parseFunctionBody enters an Expression scope for concise
  //   arrow bodies and V1 exits that scope in the same branch.
  claim <k> parseConciseArrowBody ; done => done </k>
        <stack> STACK => STACK </stack>
        <outcome> ok </outcome>
    [all-path, label(concise-arrow-body-balanced)]

  // SPEC-PROVENANCE:
  // - from_code: the block-body branch was already balanced and remains
  //   unchanged by V1.
  claim <k> parseBlockBody ; done => done </k>
        <stack> STACK => STACK </stack>
        <outcome> ok </outcome>
    [all-path, label(block-body-balance-preserved)]
endmodule
